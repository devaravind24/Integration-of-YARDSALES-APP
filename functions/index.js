/**
 * Yard Sale Treasure Map — Cloud Functions (push delivery).
 *
 * Why this exists: a client app cannot securely send a push to *another*
 * device — that requires privileged credentials (the FCM server key / Admin
 * SDK). The client therefore writes a notification *record* to Firestore, and
 * this function (running with admin privileges) fans it out to the recipient's
 * registered FCM tokens.
 *
 * Flow (Feature 4):
 *   1. App writes notifications/{id} = { userId, title, body, type, saleId? }
 *   2. onDocumentCreated fires here.
 *   3. We read users/{userId}.fcmTokens[] and send a multicast push.
 *   4. Stale/invalid tokens are pruned from the user doc.
 *
 * A second trigger sends a "new message" push when a chat message is created.
 *
 * Deploy:  firebase deploy --only functions
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

/**
 * Send a multicast push to all tokens for a user, pruning dead tokens.
 * @param {string} userId recipient uid
 * @param {object} notification {title, body}
 * @param {object} data string→string data payload for deep linking
 */
async function pushToUser(userId, notification, data) {
  if (!userId) return;

  const userSnap = await db.collection("users").doc(userId).get();
  const tokens = (userSnap.get("fcmTokens") || []).filter(Boolean);
  if (tokens.length === 0) return;

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification,
    data, // values must be strings
    android: {priority: "high"},
    apns: {payload: {aps: {sound: "default"}}},
  });

  // Prune tokens that the FCM service rejected.
  const dead = [];
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error && r.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        dead.push(tokens[i]);
      }
    }
  });
  if (dead.length > 0) {
    await db.collection("users").doc(userId).update({
      fcmTokens: FieldValue.arrayRemove(...dead),
    });
  }
}

/** Trigger: a notification record was created → deliver a push. */
exports.onNotificationCreated = onDocumentCreated(
    "notifications/{notifId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const n = snap.data();

      await pushToUser(
          n.userId,
          {title: n.title || "Yard Sale", body: n.body || ""},
          {
            type: String(n.type || "generic"),
            saleId: String(n.saleId || ""),
            chatId: String(n.chatId || ""),
            notifId: String(event.params.notifId),
          },
      );
    },
);

/**
 * Trigger: a chat message was created → push to the receiver.
 * Receiver = the chat participant that is NOT the sender.
 */
exports.onChatMessageCreated = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const msg = snap.data();

      const chatSnap = await db.collection("chats")
          .doc(event.params.chatId).get();
      if (!chatSnap.exists) return;

      const chat = chatSnap.data();
      const participants = chat.participants || [];
      const receiverId = participants.find((id) => id !== msg.senderId);
      if (!receiverId) return;

      const names = chat.participantNames || {};
      const senderName = names[msg.senderId] || "New message";
      const preview = msg.type === "image" ?
        "📷 Photo" :
        (msg.text || "");

      await pushToUser(
          receiverId,
          {title: senderName, body: preview},
          {
            type: "message",
            chatId: String(event.params.chatId),
            saleId: String(chat.saleId || ""),
          },
      );
    },
);
