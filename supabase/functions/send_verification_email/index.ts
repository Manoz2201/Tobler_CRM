import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }
  try {
    const { email, code } = await req.json();
    if (!email || !code) {
      return new Response('Missing email or code', { status: 400 });
    }
    const subject = 'Your Tobler CRM Verification Code';
    const body = `Your verification code is: ${code}`;
    console.log(`Send email to: ${email}\nSubject: ${subject}\nBody: ${body}`);
    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response('Invalid request', { status: 400 });
  }
});
