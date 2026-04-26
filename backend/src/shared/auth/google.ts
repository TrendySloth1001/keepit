import { OAuth2Client, type TokenPayload } from "google-auth-library";
import { env } from "../../constants/env";

const audience = env.GOOGLE_CLIENT_IDS.split(",").map((s) => s.trim()).filter(Boolean);

const client = new OAuth2Client();

export async function verifyGoogleIdToken(idToken: string): Promise<TokenPayload> {
  const ticket = await client.verifyIdToken({ idToken, audience });
  const payload = ticket.getPayload();
  if (!payload || !payload.sub || !payload.email) {
    throw new Error("Google token missing required claims");
  }
  return payload;
}
