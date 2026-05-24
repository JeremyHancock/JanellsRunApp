const REPO = "JeremyHancock/JanellsRunApp";
const LABELS = { bug: ["bug"], feature: ["enhancement"] };

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON" }, 400);
    }

    const { type, title, description, deviceInfo } = body;

    if (!type || !["bug", "feature"].includes(type)) {
      return json({ error: "type must be 'bug' or 'feature'" }, 400);
    }
    if (!title || title.trim().length === 0) {
      return json({ error: "title is required" }, 400);
    }
    if (!description || description.trim().length === 0) {
      return json({ error: "description is required" }, 400);
    }
    if (title.length > 200 || description.length > 5000) {
      return json({ error: "Title or description too long" }, 400);
    }

    const issueBody = deviceInfo
      ? `${description.trim()}\n\n---\n**Device:** ${deviceInfo}`
      : description.trim();

    const res = await fetch(`https://api.github.com/repos/${REPO}/issues`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "JanellsRunApp-Feedback",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        title: title.trim(),
        body: issueBody,
        labels: LABELS[type],
      }),
    });

    if (!res.ok) {
      return json({ error: "Failed to create issue" }, 502);
    }

    const issue = await res.json();
    return json({ success: true, issueNumber: issue.number }, 201);
  },
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}
