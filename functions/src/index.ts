import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as sgMail from "@sendgrid/mail";

admin.initializeApp();

sgMail.setApiKey(functions.config().sendgrid.key);

export const sendFeedbackMail = functions.firestore
  .document("feedback/{feedbackId}")
  .onCreate(async (snap) => {
    const data = snap.data();

    const username = data.username || "Unbekannt";
    const email = data.userEmail || "Keine E-Mail";
    const message = data.message || "Keine Nachricht";

    await sgMail.send({
      to: "DEINEEMAIL@gmail.com",
      from: "DEINE_VERIFIZIERTE_SENDGRID_EMAIL@gmail.com",
      subject: "Neues Feedback",
      html: `
        <h2>Neues Feedback</h2>
        <p><strong>Benutzer:</strong> ${username}</p>
        <p><strong>Email:</strong> ${email}</p>
        <hr>
        <p>${message}</p>
      `,
    });
  });
