/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { setGlobalOptions } = require("firebase-functions");
const { onCall, onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const midtransClient = require("midtrans-client");
const cors = require('cors')({ origin: true });

admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Initialize Midtrans Core API
const core = new midtransClient.CoreApi({
  isProduction: false, // Set to true for production
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY // Optional, but good practice
});

/**
 * Creates a Midtrans transaction for QRIS payment using Core API.
 * 
 * Expected data:
 * - orderId: string (Booking ID)
 * - amount: number (Total Price)
 * 
 * Returns:
 * - qrString: string (Raw QR Code String)
 * - transactionId: string
 */
exports.createMidtransTransaction = onCall(async (request) => {
  // Authentication check
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  // Debug Logging
  logger.info("createMidtransTransaction (Core API) called");
  if (!process.env.MIDTRANS_SERVER_KEY) {
    logger.error("MIDTRANS_SERVER_KEY is missing in environment variables");
    throw new HttpsError('failed-precondition', 'Server configuration error');
  }

  const { orderId, amount } = request.data;
  logger.info("Request Data:", { orderId, amount });

  if (!orderId || !amount) {
    throw new HttpsError(
      'invalid-argument',
      'The function must be called with one argument "orderId" and "amount".'
    );
  }

  try {
    const parameter = {
      payment_type: "qris",
      transaction_details: {
        order_id: orderId,
        gross_amount: Math.round(amount), // Ensure integer for IDR
      },
      qris: {
        acquirer: "gopay", // Optional, can be left out to let Midtrans decide
      },
    };

    logger.info("Calling Midtrans Core API with:", parameter);

    const response = await core.charge(parameter);

    logger.info("Core API Response:", response);

    // For QRIS, the response should contain actions with the QR string
    // Usually response.actions[0].url is the QR image, but for raw string we might check other fields
    // Midtrans Core API for QRIS usually returns `qr_string` directly in the response body if successful.

    // Check for qr_string
    const qrString = response.qr_string;

    if (!qrString) {
      logger.error("No qr_string found in response", response);
      throw new Error("Failed to retrieve QR String from Midtrans");
    }

    // Save QR String to Firestore so it persists
    await admin.firestore().collection('bookings').doc(orderId).update({
      qrString: qrString,
      midtransTransactionId: response.transaction_id,
    });

    return {
      qrString: qrString,
      transactionId: response.transaction_id,
    };
  } catch (error) {
    logger.error("Error creating transaction", error);
    throw new HttpsError('internal', `Midtrans Error: ${error.message || error}`, error);
  }
});

/**
 * Webhook listener for Midtrans payment status updates.
 */
exports.midtransWebhook = onRequest(async (req, res) => {
  cors(req, res, async () => {

    try {
      const notificationJson = req.body;

      // Verify signature key (Optional but recommended)
      // const signatureKey = notificationJson.signature_key;
      // const orderId = notificationJson.order_id;
      // const statusCode = notificationJson.status_code;
      // const grossAmount = notificationJson.gross_amount;
      // const mySignatureKey = crypto.createHash('sha512').update(orderId + statusCode + grossAmount + process.env.MIDTRANS_SERVER_KEY).digest('hex');
      // if (signatureKey !== mySignatureKey) {
      //   return res.status(403).send('Invalid signature');
      // }

      let statusResponse;
      try {
        statusResponse = await core.transaction.notification(notificationJson);
      } catch (e) {
        logger.warn("Midtrans SDK verification failed (likely simulation), using body directly:", e.message);
        statusResponse = notificationJson;
      }

      const orderId = statusResponse.order_id;
      const transactionStatus = statusResponse.transaction_status;
      const fraudStatus = statusResponse.fraud_status;

      logger.info(`Transaction notification received for ${orderId}: ${transactionStatus}`);

      let bookingStatus = null;

      if (transactionStatus == 'capture') {
        if (fraudStatus == 'challenge') {
          // TODO: Handle challenge
          bookingStatus = 'pending';
        } else if (fraudStatus == 'accept') {
          bookingStatus = 'paid';
        }
      } else if (transactionStatus == 'settlement') {
        bookingStatus = 'paid';
      } else if (transactionStatus == 'cancel' ||
        transactionStatus == 'deny' ||
        transactionStatus == 'expire') {
        bookingStatus = 'cancelled';
      } else if (transactionStatus == 'pending') {
        bookingStatus = 'pending';
      }

      if (bookingStatus) {
        await admin.firestore().collection('bookings').doc(orderId).update({
          status: bookingStatus,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info(`Booking ${orderId} updated to ${bookingStatus}`);
      }

      res.status(200).send('OK');
    } catch (error) {
      logger.error("Error processing webhook", error);
      res.status(500).send('Internal Server Error');
    }
  });
});

/**
 * Manually syncs the transaction status from Midtrans to Firestore.
 * Useful for updating past transactions that missed the webhook.
 */
exports.syncTransactionStatus = onCall(async (request) => {
  const { orderId } = request.data;

  logger.info(`Syncing status for ${orderId}`);

  if (!orderId) {
    throw new HttpsError('invalid-argument', 'The function must be called with "orderId".');
  }

  try {
    // 1. Get status from Midtrans
    const statusResponse = await core.transaction.status(orderId);
    const transactionStatus = statusResponse.transaction_status;
    const fraudStatus = statusResponse.fraud_status;

    logger.info(`Midtrans status for ${orderId}: ${transactionStatus}`);

    // 2. Determine Firestore status
    let bookingStatus = null;
    if (transactionStatus == 'capture') {
      if (fraudStatus == 'challenge') {
        bookingStatus = 'pending';
      } else if (fraudStatus == 'accept') {
        bookingStatus = 'paid';
      }
    } else if (transactionStatus == 'settlement') {
      bookingStatus = 'paid';
    } else if (transactionStatus == 'cancel' ||
      transactionStatus == 'deny' ||
      transactionStatus == 'expire') {
      bookingStatus = 'cancelled';
    } else if (transactionStatus == 'pending') {
      bookingStatus = 'pending';
    }

    // 3. Update Firestore if status is determined
    if (bookingStatus) {
      await admin.firestore().collection('bookings').doc(orderId).update({
        status: bookingStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        midtransStatusRaw: transactionStatus // Optional: save raw status for debug
      });
      return { success: true, status: bookingStatus, midtransStatus: transactionStatus };
    } else {
      return { success: false, message: "Unknown status mapping", midtransStatus: transactionStatus };
    }

  } catch (error) {
    logger.error("Error syncing transaction", error);
    // If transaction doesn't exist in Midtrans (404), it might be a test booking that was never paid
    if (error.message && error.message.includes('404')) {
      return { success: false, message: "Transaction not found in Midtrans" };
    }
    throw new HttpsError('internal', `Midtrans Error: ${error.message || error}`, error);
  }
});
