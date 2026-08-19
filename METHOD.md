# How I work

*A general method, not a description of any one project. The examples come from
real work, but every rule here is meant to travel.*

Most of this is about one thing: **not fooling yourself.** Code that is wrong
usually looks fine. Measurements that are wrong usually look reasonable. Notes
that are wrong usually sound confident. The rules below exist because each one
has caught something real that all three of those disguises got past.

---

## 0. The one rule

**Verify, never recall.**

If a fact can be checked against a file, a tool, a datasheet or a command, check
it. Do not answer from memory, and do not answer from what a document says
either — documents are memory that someone else wrote down.

This sounds obvious. It is the rule broken most often, because recalled facts
arrive feeling exactly like known facts. There is no internal signal that
separates them. The only defence is a habit: **before stating it, go and look.**

Three real cases, all from one project:

- Eight pin assignments were wrong for weeks. They were correct — for a
  different revision of the same board.
- Timing was measured against the wrong speed grade for weeks, because the
  manual said one thing and the part on the desk said another. **A datasheet
  describes a product line, not the unit in front of you.**
- A note said a fix was "not done". The code twenty lines below it already did
  the fix. **A "not done" note is a claim like any other, and rots the same way.**

The corollary that costs the most to learn: **your own earlier statements are
recall too.** Re-check them with the same suspicion you'd give someone else's.

---

## 1. Before you measure anything

### Change one thing

A measurement with two variables moving is not a measurement. It is an anecdote
with numbers attached.

The discipline that makes this practical: **make every option a switch.** A
parameter, a build flag, a define. Then an experiment is two builds of
*identical source*, one switch apart. Nobody has to trust that the two versions
were "basically the same" — they provably were.

When three things genuinely moved at once, **say so and refuse to quote a
speedup**. A number that can't be attributed is worse than no number, because it
gets repeated.

### Write the prediction down first

Before running it, write what you expect and why. Then the run can **falsify**
you instead of merely agreeing with you.

This is not ceremony. It changes what you notice. If you predict "this should
save about 11,000 cycles because each of those 225 operations costs about 50"
and it saves 10,497, you have learned that your model of the system is right. If
it saves 60,000, you have learned something much more interesting — and without
the prediction you'd have just written down "60,000" and moved on.

### Know what your denominator is

This is the single most common way to be wrong by an order of magnitude while
holding a correct number.

A counter counts *something*. Before dividing by anything, ask: **what exactly
is on the bottom?**

Real cases, same project, four separate times:

- A counter of *events* was read as a count of *lost time*. Overstated by 10x on
  one workload and 100x on another.
- A number measured over a narrow window was quoted as a share of the whole run.
  25% and 9.5% are the same measurement against two different denominators.
- A "share of runtime" column was actually a share of a *sub-interval* of
  runtime, and was labelled wrongly for months.

**Keep both columns when there are two.** Don't pick one and hope.

### Know who is reporting

If your number comes from one observer, ask whether that observer is typical.

A benchmark reported one node's clock. That node happened to be the one the
traffic pattern favoured, so it finished early and its timer stopped early. The
headline said a fix made things 9% *worse*. Measured across all nodes, the same
fix was **1.87x better**.

**A number taken from one participant flatters whichever participant the system
favours.** Three separate metrics in that project had this bug.

---

## 2. Tests that can actually fail

**A green test that cannot fail is not evidence.**

The check: **break the thing on purpose and confirm the test goes red.** If it
stays green, the test was decorative. Fix the test, then re-break, then confirm.

This is mutation testing, and it is the cheapest high-value practice there is.
In one project it caught real problems seven times — and **three of those times
the test was the thing at fault**, not the code.

Two subtleties that matter:

**A mutation that fails to create the condition proves nothing.** One attempt to
break an assertion didn't actually change the state the assertion watched. That
left the assertion *untested*, not *validated*. Notice the difference — a
mutation that "passes" is a failed experiment, not a passed one.

**A mutation that survives in one test and dies in another is information about
the tests.** It tells you the first test never enters that code path. That is
worth more than the mutation itself.

Corollary for coverage: **a test written from how the code is actually called
tests the happy path by construction.** Real defects live at zero, at maximum,
and at one-past-the-end. Go there deliberately.

---

## 3. Debugging

**Never fix what you haven't reproduced.**

If you can't make the failure happen on demand, you cannot know you fixed it.
You can only know it stopped happening while you were watching. Those are not
the same thing, and the difference shows up later, in front of someone else.

The order:

1. **Reproduce it.** Exact command, exact input, exact output. Capture the real
   error text, not a paraphrase of it.
2. **Read what it actually says.** All of it. Slowly. When errors cascade, walk
   back to the *first* one — the loudest error is usually a casualty.
3. **One hypothesis at a time.** State it, state what you'd expect to see if it
   were true, then look. Changing three things and watching the bug vanish
   teaches you nothing and usually plants the next one.
4. **Fix the cause.** The gate: *can you explain in one sentence why the code
   produced exactly this wrong behaviour?* If the fix doesn't follow from that
   sentence, you haven't found the cause.
5. **Prove it.** Re-run the original failing case. Then look for the same mistake
   elsewhere — causes usually have siblings, and you will never understand the
   pattern better than you do right now.

**Banned, because they hide bugs rather than fix them:** a catch that silences
the error, a fallback that masks the failure, a special case for the one input
that broke, a retry until it passes.

---

## 4. When something doesn't work

**A mechanism that doesn't help is evidence about your workload, not proof about
the mechanism.**

This one has saved more good work than any other rule here.

In one project, four separate improvements were built, measured, found useless,
and nearly deleted. Then someone profiled the *benchmark* rather than the
system, and found the benchmark was broken — it was accidentally driving every
node at one target instead of spreading the load. Fixed that, re-ran the same
four unchanged mechanisms, and **three of them reversed**. One went from "4%
worse" to a 1.56x speedup.

Later, the same thing happened again for a different reason: the mechanisms were
being judged against a system whose real constraint was somewhere else entirely.
Once that constraint moved, they all came good.

**So before rejecting something, ask what the system's actual limit was while
you measured.** Five instances in one project, which is enough to call it a law
rather than an anecdote.

The general shape: **when a result surprises you, suspect the measurement before
the thing measured.** Not always right. Right often enough to check first.

And the flip side, which is just as important: **when a mechanism genuinely
doesn't pay, keep the negative result.** Write it down as a result. A documented
"we tried this, here is the number, it doesn't help here and here is why" is
real work, and it stops the next person spending a week on it.

---

## 5. Reading numbers correctly

**Say which version a number came from.** The moment a system has two
configurations, every number needs a label. Two numbers from different builds
divided by each other produce a ratio that means nothing, and it looks exactly
like a ratio that means something.

**Separate the units.** A change that removes 50% of the steps but makes each
step 10% slower is not a 2x improvement. Track both and quote the one that
matters to the user — usually **time**, not step count. Every intermediate
number can be steps; the headline should be duration.

**Constants are the check.** If a change should cost or save a fixed amount,
verify it actually is fixed. Real examples:

- A saving that should not depend on the input measured **10,497 cycles at two
  very different inputs — identical to the digit.** That agreement is what
  proves the saving came from where you think.
- Four builds that should differ from a baseline by one fixed startup cost came
  out **183, 178, 178 and 181** apart. One constant, four configurations, across
  runtimes differing by a factor of two. Nothing else moved.
- A change that adds one register per unit should add exactly *N* registers.
  Counting them is a structural check that survives placement noise, where the
  headline area numbers do not.

**When two things should agree and don't, find the difference before explaining
it.** Usually one of them has a different denominator, a different version, or a
different observer.

**Two independent routes to the same answer beat one careful route.** If a
predicted ratio of 3.5x measures as 3.21x by a completely different method, you
have something. One number from one method is a data point; two agreeing numbers
from unrelated methods is a result.

---

## 6. Attacking your own work

The productive question before finishing anything: **what would make this
wrong?** Then go and check that specific thing.

Where defects actually live:

- **Boundaries.** Zero. Maximum. One past the end. Empty. A single element.
- **The inverse.** If you change one direction of a two-way mapping, **the other
  direction is a bug until proven otherwise.** Same for a guard applied to one
  of two symmetric paths.
- **The thing nobody has run.** A whole class of defect is invisible to every
  test you have and obvious to the first different tool you try. Run the
  different tool early, not at the end.
- **What the framework was doing for you.** Before assuming your code handles
  something, check whether a library, a default, or a parameter was quietly
  handling it. When that thing changes, the gap appears somewhere unrelated and
  looks like a new bug.
- **What the compiler did to your work.** Work can be *deleted* as dead, and it
  can also be *solved* — if the operation you're repeating is algebraically
  collapsible, an optimiser will do it once instead of *n* times, and your
  timing curve will be flat for reasons that have nothing to do with your
  system. Guard with a correctness check, not an instruction count.

**Prefer a cheap decisive test over a confident estimate.** A one-iteration run
that answers the question in 30 seconds beats an hour of reasoning about whether
the four-iteration run is hung. Estimates talk you out of correct conclusions.

**Check your own arithmetic mechanically.** I have written a wrong hex conversion
into a document that was otherwise carefully verified. Now I write three lines of
script to check every number pair in the document. It takes a minute and it has
caught things.

---

## 7. Documents rot

Every note is a claim with a timestamp you can't see.

- **Documenting a trap does not prevent it.** One trap was written up in two
  separate places and still happened again. **Prefer an assertion that aborts
  over a comment that warns.** If a mistake is possible, make it impossible, or
  make the tool refuse. A comment is a suggestion to a person who is busy.
- **Hardcoded counts drift silently.** "60 commits ahead" was true for one day.
  If a number changes, write down *how to get it*, not the number.
- **Notes describing work as pending outlive the work.** Audit the "not done"
  and "not yet attempted" lines specifically. They are the ones nobody re-reads,
  and they actively mislead — they invite someone to go and do a thing that is
  already done, or already refused for a reason.
- **A plan expressed in terms of something mutable decays.** "We can undo this by
  deleting that branch" stopped being true the moment unrelated work landed on
  that branch — following it would have destroyed the main work and left the
  thing it targeted untouched. **Tie a plan to the files a change occupies, not
  to the container it arrived in.**

---

## 8. Reporting honestly

**Say plainly what has and has not been done.** Not as a disclaimer at the end —
as part of the claim.

The distinctions that matter most are the ones easiest to blur:

- What ran **for real** versus what ran **in a model**.
- What was **measured** versus what was **calculated from a measurement**.
- What ran **once** versus what has been **repeated**.
- What is **your work** versus what you **configured** or **imported**.

That last one is worth being scrupulous about in both directions. Claiming
someone else's component is bad. But so is under-claiming: if you configured
something carefully, measured the alternatives, and chose on evidence, that *is*
your contribution and it should be described as one.

**When you find your own error, correct it plainly and move on.** State it in a
sentence, fix it, continue. No extended apology, no re-litigating how it
happened. The correction is the useful part; the performance around it isn't.

**When someone challenges a claim, go and check it — don't reassure them.** In
one project, challenges from a non-expert found real bugs repeatedly, because
"are you sure?" is a request for evidence and the honest response is to produce
some. Reassurance costs nothing and is worth nothing.

---

## 9. Working practices

Small things that compound:

- **Never edit a file a running job is reading.** Obvious, easy to do by
  accident, and it produces results you can't trust and can't distinguish from
  real ones. If you did it, say so and re-run rather than reasoning about
  whether it mattered.
- **Long job in the background, read-only work in the foreground.** Auditing
  documents, reading source, checking arithmetic — none of it touches the
  running job.
- **Restore the state you borrowed.** If a check regenerated a config file,
  put it back and *verify* it went back.
- **Killing the wrapper does not kill the work.** More than once, stopping a job
  killed the handle and left the actual process running. Check for the process,
  not for the handle.
- **Serialise things that share a resource** — a build directory, a licence, a
  file. A lock is three lines and saves an hour.
- **Commit messages should say why, and what was ruled out.** The history is the
  only place the reasoning survives. "Fixed bug" is a wasted opportunity; the
  measurement you took, the alternative you rejected, and the number that
  decided it are all worth more later than the diff.

---

## 10. Scope

Do the thing that was asked. All of it.

- **Don't quietly narrow it.** If part of it is blocked, do everything else in
  full and say explicitly what you left out and why. Scaling the work down is the
  requester's decision, not yours.
- **Don't quietly widen it either.** An adjacent improvement you noticed is worth
  *mentioning*, not worth doing unasked.
- **Make the routine judgement calls yourself.** Ask only when two readings of
  the request would produce genuinely different work.
- **If you raise a concern and it's overruled, that's the decision.** Say so once,
  then build the thing properly.

And the one that's easy to forget under pressure: **being fast is not the goal,
being right is.** A wrong answer delivered quickly costs more than it saved,
because someone acts on it.

---

## The short version

If you only keep five:

1. **Verify, never recall** — including your own earlier statements.
2. **Change one thing**, and write down what you expect before you run it.
3. **Break it on purpose.** A test that cannot fail is not evidence.
4. **Never fix what you haven't reproduced.**
5. **When a result surprises you, suspect the measurement first** — and when
   something doesn't help, ask what the real constraint was while you measured.
