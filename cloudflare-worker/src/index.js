const REPO = "JeremyHancock/JanellsRunApp";
const LABELS = { bug: ["bug"], feature: ["enhancement"] };

// The app is the only caller and it's native, so there's no CORS. Anyone can still find
// this URL in the public repo: the rate limit keeps them from flooding the issue list.
export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    if (env.FEEDBACK_LIMIT) {
      const ip = request.headers.get("CF-Connecting-IP") || "unknown";
      const { success } = await env.FEEDBACK_LIMIT.limit({ key: ip });
      if (!success) return json({ error: "Too many requests" }, 429);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON" }, 400);
    }

    if (body === null || typeof body !== "object") {
      return json({ error: "Invalid JSON" }, 400);
    }
    const { type, title, description, deviceInfo } = body;

    if (!["bug", "feature"].includes(type)) {
      return json({ error: "type must be 'bug' or 'feature'" }, 400);
    }
    if (typeof title !== "string" || title.trim().length === 0) {
      return json({ error: "title is required" }, 400);
    }
    if (typeof description !== "string" || description.trim().length === 0) {
      return json({ error: "description is required" }, 400);
    }
    if (title.length > 200 || description.length > 5000) {
      return json({ error: "Title or description too long" }, 400);
    }

    // App versions before 1.3 put the user's name in front of the device line. The issue is
    // public, so drop it here too.
    const device = typeof deviceInfo === "string" ? deviceInfo.split(" — ").pop().slice(0, 200) : "";
    const text = plain(description.trim());
    const issueBody = device ? `${text}\n\n---\n**Device:** ${plain(device)}` : text;

    const res = await fetch(`https://api.github.com/repos/${REPO}/issues`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
        "User-Agent": "JanellsRunApp-Feedback",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        title: plain(title.trim()),
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

// Issues are filed with the repo owner's token, so an "@name" in the text would notify that
// person as if the owner had written it. A zero-width space after the @ stops the mention.
function plain(text) {
  return text.replace(/@(?=[A-Za-z0-9])/g, "@\u200b");
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
