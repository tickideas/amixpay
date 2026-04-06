const config = require('../config');

/**
 * Send an email. Tries SendGrid first, falls back to SMTP (nodemailer), falls back to console log.
 */
async function sendEmail({ toEmail, subject, html, text }) {
  // --- SendGrid ---
  if (config.email.sendgridKey && config.email.sendgridKey.startsWith('SG.')) {
    try {
      const sgMail = require('@sendgrid/mail');
      sgMail.setApiKey(config.email.sendgridKey);
      await sgMail.send({
        to: toEmail,
        from: { email: config.email.from, name: 'AmixPay' },
        subject,
        html,
        text: text || subject,
      });
      return;
    } catch (err) {
      console.error('[Email/SendGrid] Failed:', err.message);
    }
  }

  // --- SMTP fallback (nodemailer) ---
  if (config.email.smtpHost && config.email.smtpUser) {
    try {
      const nodemailer = require('nodemailer');
      const transporter = nodemailer.createTransport({
        host: config.email.smtpHost,
        port: config.email.smtpPort || 587,
        secure: config.email.smtpPort === 465,
        auth: { user: config.email.smtpUser, pass: config.email.smtpPass },
      });
      await transporter.sendMail({
        from: `"AmixPay" <${config.email.from || config.email.smtpUser}>`,
        to: toEmail,
        subject,
        html,
        text: text || subject,
      });
      return;
    } catch (err) {
      console.error('[Email/SMTP] Failed:', err.message);
    }
  }

  // --- Last resort: log to console (visible in Railway logs) ---
  console.log(`[Email] To: ${toEmail} | Subject: ${subject}`);
  if (text) console.log(`[Email] Body: ${text}`);
}

async function sendPasswordReset({ toEmail, firstName, resetLink }) {
  const subject = 'Reset your AmixPay password';
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;padding:32px 24px;background:#f5f7fa;border-radius:12px;">
      <div style="text-align:center;margin-bottom:24px;">
        <span style="font-size:28px;font-weight:900;color:#0D6B5E;letter-spacing:-1px;">AmixPay</span>
      </div>
      <div style="background:#fff;border-radius:10px;padding:28px;">
        <h2 style="margin:0 0 12px;font-size:20px;color:#111;">Hi ${firstName || 'there'},</h2>
        <p style="color:#555;line-height:1.6;margin:0 0 20px;">
          We received a request to reset your AmixPay password. Click the button below to set a new password.
          This link expires in <strong>1 hour</strong>.
        </p>
        <div style="text-align:center;margin:28px 0;">
          <a href="${resetLink}"
             style="background:#0D6B5E;color:#fff;text-decoration:none;padding:14px 32px;border-radius:8px;font-size:16px;font-weight:700;display:inline-block;">
            Reset Password
          </a>
        </div>
        <p style="color:#999;font-size:13px;margin:0;">
          If you didn't request this, you can safely ignore this email. Your password will not change.
        </p>
      </div>
      <p style="text-align:center;color:#bbb;font-size:12px;margin-top:20px;">
        © ${new Date().getFullYear()} AmixPay · Moving money made simple
      </p>
    </div>
  `;
  const text = `Hi ${firstName || 'there'},\n\nReset your AmixPay password here:\n${resetLink}\n\nThis link expires in 1 hour.\n\nIf you didn't request this, ignore this email.`;
  await sendEmail({ toEmail, subject, html, text });
}

async function sendVerificationCode({ toEmail, firstName, code }) {
  const subject = 'Verify your AmixPay email';
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;padding:32px 24px;background:#f5f7fa;border-radius:12px;">
      <div style="text-align:center;margin-bottom:24px;">
        <span style="font-size:28px;font-weight:900;color:#0D6B5E;letter-spacing:-1px;">AmixPay</span>
      </div>
      <div style="background:#fff;border-radius:10px;padding:28px;">
        <h2 style="margin:0 0 12px;font-size:20px;color:#111;">Hi ${firstName || 'there'},</h2>
        <p style="color:#555;line-height:1.6;margin:0 0 20px;">
          Enter this 6-digit code in the AmixPay app to verify your email address.
          The code expires in <strong>30 minutes</strong>.
        </p>
        <div style="text-align:center;margin:28px 0;">
          <div style="display:inline-block;background:#0D6B5E;color:#fff;padding:18px 40px;border-radius:12px;font-size:36px;font-weight:900;letter-spacing:10px;">
            ${code}
          </div>
        </div>
        <p style="color:#999;font-size:13px;margin:0;">
          If you didn't create an AmixPay account, you can safely ignore this email.
        </p>
      </div>
      <p style="text-align:center;color:#bbb;font-size:12px;margin-top:20px;">
        © ${new Date().getFullYear()} AmixPay · Moving money made simple
      </p>
    </div>
  `;
  const text = `Hi ${firstName || 'there'},\n\nYour AmixPay verification code is: ${code}\n\nIt expires in 30 minutes.\n\nIf you didn't sign up, ignore this email.`;
  await sendEmail({ toEmail, subject, html, text });
}

async function sendWelcome({ toEmail, firstName }) {
  const subject = 'Welcome to AmixPay!';
  const html = `
    <div style="font-family:Arial,sans-serif;max-width:520px;margin:0 auto;padding:32px 24px;background:#f5f7fa;border-radius:12px;">
      <div style="text-align:center;margin-bottom:24px;">
        <span style="font-size:28px;font-weight:900;color:#0D6B5E;">AmixPay</span>
      </div>
      <div style="background:#fff;border-radius:10px;padding:28px;">
        <h2 style="color:#111;">Welcome, ${firstName}! 🎉</h2>
        <p style="color:#555;line-height:1.6;">
          Your AmixPay account is ready. You can now send money, hold multiple currencies,
          and transfer internationally — all from one app.
        </p>
        <p style="color:#555;line-height:1.6;">
          Complete your KYC to unlock higher limits and all features.
        </p>
      </div>
    </div>
  `;
  await sendEmail({ toEmail, subject, html });
}

module.exports = { sendEmail, sendPasswordReset, sendWelcome, sendVerificationCode };
