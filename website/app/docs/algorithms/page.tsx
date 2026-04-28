import type { Metadata } from "next";
import Math from "@/components/docs/Math";

export const metadata: Metadata = {
  title: "Algorithms — Keepit Docs",
  description: "Cursor pagination, atomic quota reservation, resumable multipart, time-bucket aggregation.",
};

export default function Algorithms() {
  return (
    <>
      <h1>Algorithms</h1>
      <p className="lede">
        The interesting work in Keepit&rsquo;s backend isn&rsquo;t the surface API —
        it&rsquo;s the small set of carefully chosen algorithms underneath. Each one is
        documented here with its formal model and complexity.
      </p>

      <h2 id="pagination">1. Keyset (cursor) pagination</h2>
      <p>
        Listing uses keyset pagination, not <code>OFFSET</code>. Each page is a seek on the
        composite index <Math tex={String.raw`I = (\mathsf{userId}, \mathsf{updatedAt}\!\downarrow, \mathsf{id}\!\downarrow)`} />.
      </p>
      <p>The cursor is a tuple</p>
      <Math display tex={String.raw`
        c \;=\; \bigl(t^{*},\, i^{*}\bigr)
      `} />
      <p>where <Math tex="t^{*}" /> and <Math tex="i^{*}" /> are the <code>updatedAt</code> and <code>id</code> of the last row of the previous page. The query is then</p>
      <Math display tex={String.raw`
        \mathsf{Page} \;=\; \bigl\{ r \in I \;\big|\; r.\mathsf{userId} = u
        \;\wedge\; (r.t,\, r.\mathsf{id}) \prec_{\text{lex}} (t^{*}, i^{*}) \bigr\}
      `} />
      <p>limited to <Math tex="L+1" /> rows. The lexicographic ordering ensures determinism even when two rows share <Math tex="t^{*}" />.</p>

      <h3>Complexity</h3>
      <p>
        With a B-tree on <Math tex="I" />, the seek to the cursor takes
        <Math tex={String.raw`\;O(\log N)`} /> and the scan is
        <Math tex={String.raw`\;O(L)`} />:
      </p>
      <Math display tex={String.raw`
        T_{\text{page}} \;=\; O(\log N \,+\, L)
      `} />
      <p>
        independent of how deep the user scrolls. By contrast, OFFSET pagination is
        <Math tex={String.raw`\;O(\mathsf{offset} + L)`} /> — i.e. linear in the page
        index, which becomes ruinous past a few thousand rows.
      </p>

      <h2 id="quota">2. Atomic quota reservation</h2>
      <p>
        Every user has a quota <Math tex="Q" /> and a counter <Math tex="b" /> of bytes
        currently used. An upload of size <Math tex={String.raw`\;\delta`} /> must satisfy
        <Math tex={String.raw`\;b + \delta \le Q`} />.
      </p>
      <p>
        Naive read-then-write is racy under concurrent uploads:
      </p>
      <Math display tex={String.raw`
        \begin{aligned}
        T_1:\;& \text{read } b \;=\; b_0 \\
        T_2:\;& \text{read } b \;=\; b_0 \\
        T_1:\;& \text{check } b_0 + \delta_1 \le Q,\; \text{write } b \!:= b_0 + \delta_1 \\
        T_2:\;& \text{check } b_0 + \delta_2 \le Q,\; \text{write } b \!:= b_0 + \delta_2 \\
        \end{aligned}
      `} />
      <p>The lost update means both transactions believed they fit. Keepit replaces the pattern with a single conditional UPDATE:</p>
<pre><code>{`UPDATE "User"
   SET "bytesUsed" = "bytesUsed" + :δ
 WHERE "id" = :u
   AND "bytesUsed" + :δ <= "quotaBytes";`}</code></pre>
      <p>
        Under PostgreSQL&rsquo;s default <em>read committed</em> isolation, each row update
        takes a row-level lock; concurrent writers serialize on that lock and re-evaluate
        the predicate. The statement is its own atomic check:
      </p>
      <Math display tex={String.raw`
        \mathsf{Reserve}(u, \delta) \;=\;
        \begin{cases}
          \texttt{ok} & \text{if } b_u + \delta \le Q_u \\
          \texttt{quota\_exceeded} & \text{otherwise}
        \end{cases}
      `} />
      <p>
        and returns <code>0 rows affected</code> in the second case. Every error path
        (aborted upload, finalize-time size mismatch, missing object, batch delete) calls
        the inverse <Math tex={String.raw`\mathsf{Refund}(u, \delta)`} />.
      </p>
      <p>
        The protocol guarantees, for any concurrent schedule, that
        <Math tex={String.raw`\;b_u \le Q_u`} /> holds at every committed snapshot.
      </p>

      <h2 id="multipart">3. Resumable multipart upload</h2>
      <p>
        Encrypted blobs are split into <Math tex="n" /> chunks of size
        <Math tex={String.raw`\;\sigma = 5\,\text{MiB}`} /> with a final remainder. For an
        item of declared size <Math tex={String.raw`\;S = \mathsf{fileSize}`} />:
      </p>
      <Math display tex={String.raw`
        n \;=\; \left\lceil \frac{S}{\sigma} \right\rceil,\quad
        s_k \;=\;
        \begin{cases}
          \sigma & 1 \le k < n \\
          S - (n-1)\sigma & k = n
        \end{cases}
      `} />
      <p>
        Each chunk write is idempotent on <Math tex={String.raw`\;(\mathsf{itemId}, k)`} />
        via an <code>UPSERT</code> that replaces the prior <Math tex={String.raw`\mathsf{eTag}`} />.
        On <em>finalize</em>, the server requires:
      </p>
      <Math display tex={String.raw`
        \sum_{k=1}^{n} s_k \;=\; S
      `} />
      <p>and rejects with <code>422</code> otherwise. After S3
      <code> CompleteMultipartUpload </code>the server <code>HEAD</code>s the object and
      requires the stored byte-length to also equal <Math tex="S" />, otherwise it tears
      down both the row and the object and refunds quota.</p>

      <h3>Resumability</h3>
      <p>
        A crashed client retransmits only chunks for which it never received an ETag. The
        server&rsquo;s expected work to finalize after a partial upload is bounded by:
      </p>
      <Math display tex={String.raw`
        T_{\text{resume}} \;\le\; O\!\bigl(n - |\,\mathsf{seen}\,|\bigr) \cdot \tau_{\text{net}}
      `} />
      <p>and the user is never charged twice for the same bytes.</p>

      <h2 id="timeline">4. Time-bucket aggregation</h2>
      <p>
        The timeline endpoint groups items into discrete buckets using
        <code> date_trunc</code>. Define the bucket function for granularity
        <Math tex={String.raw`\;g \in \{\mathsf{day}, \mathsf{week}, \mathsf{month}\}`} /> as:
      </p>
      <Math display tex={String.raw`
        B_g(t) \;=\; \mathrm{date\_trunc}(g,\; t)
      `} />
      <p>The aggregation is:</p>
      <Math display tex={String.raw`
        \mathsf{Series}_{u, g}\bigl[\,\tau_0,\, \tau_1\,\bigr]
        \;=\; \Bigl\{
          \bigl(B_g(t),\;\textstyle\sum s,\;\#\bigr)
          \,\Big|\,
          (t, s) \in \mathsf{Items}_u,\;
          \tau_0 \le t < \tau_1
        \Bigr\}
      `} />
      <p>
        with bytes summed via <Math tex={String.raw`\sum \mathrm{COALESCE}(s, 0)`} />. The
        resulting series is <em>sparse</em> — empty buckets are omitted to keep the response
        small for inactive accounts.
      </p>

      <h3>Safety</h3>
      <p>
        The <Math tex="g" /> token is whitelisted to one of the three values before being
        interpolated into the SQL — it never reaches the planner as user input, eliminating
        the SQL-injection vector that would otherwise apply to dynamic
        <code> date_trunc </code>arguments.
      </p>

      <h2 id="search">5. Search pattern escaping</h2>
      <p>
        Title search uses PostgreSQL <code>ILIKE</code> with a sanitized pattern.
        For input string <Math tex="q" /> we form:
      </p>
      <Math display tex={String.raw`
        \hat{q} \;=\; \mathsf{escape}_{\text{LIKE}}(q),\quad
        p \;=\; \texttt{"\%"} \,\|\, \hat{q} \,\|\, \texttt{"\%"}
      `} />
      <p>
        where <Math tex={String.raw`\mathsf{escape}_{\text{LIKE}}`} /> backslash-escapes the
        three LIKE metacharacters
        <Math tex={String.raw`\;\{\,\%,\;\_,\;\backslash\,\}`} />. This prevents wildcard
        injection (e.g. a leading <Math tex={String.raw`\%`} /> turning a prefix search into
        a full scan) and limits pathological inputs to honest substring matches.
      </p>
      <p>
        For very large datasets, swap to a trigram index
        <Math tex={String.raw`\;\mathsf{gin\_trgm\_ops}`} /> for sub-linear ILIKE; the query
        plan changes but the API surface does not.
      </p>

      <h2 id="batch-delete">6. Batch delete with quota reconciliation</h2>
      <p>
        Given a set <Math tex="D" /> of item ids (<Math tex={String.raw`|D| \le 200`} />)
        owned by user <Math tex="u" />, with file sizes
        <Math tex={String.raw`\;\{\, s_i \,\}_{i \in D}`} />, the delete proceeds in one
        transaction:
      </p>
      <Math display tex={String.raw`
        \begin{aligned}
        \Sigma   \;&=\; \textstyle\sum_{i \in D} s_i \\
        b_u      \;&\!:=\; b_u - \Sigma \\
        \mathsf{Items} \;&\!:=\; \mathsf{Items} \setminus D
        \end{aligned}
      `} />
      <p>
        Object-store deletions are issued <em>after</em> the transaction commits, in
        parallel via <Math tex={String.raw`\mathsf{Promise.allSettled}`} />, so a slow
        S3 round-trip cannot extend the database lock window. A failed
        object delete is logged and reconciled by a janitor sweep — the row is already
        gone, so no client request can leak the orphaned bytes.
      </p>
    </>
  );
}
