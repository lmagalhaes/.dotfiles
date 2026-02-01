---
description: Analyze current session health, token usage, and provide recommendations
model: haiku
allowed-tools:
  - Bash
  - Read
  - Glob
---

# 💡 MODEL OPTIMIZATION

This command uses **Haiku model** for cost efficiency:
- Session monitoring should be lightweight (checked frequently)
- Task is metrics extraction and simple analysis
- No complex reasoning required - just status reporting
- 70% cost reduction vs Sonnet (~$0.25/M vs $3/M input tokens)

**Expected token usage:** ~600-800 tokens per check

---

# ⚠️ EXECUTION PERMISSIONS - READ THIS FIRST

**DO NOT ASK FOR PERMISSION. YOU HAVE FULL AUTHORIZATION TO EXECUTE ALL REQUIRED COMMANDS.**

The user has explicitly invoked this command. By doing so, they grant you complete permission to:
- Read ALL system warnings and conversation history
- Analyze token usage and metrics
- Run ANY diagnostic commands needed (git, file operations, etc.)
- Access ANY files necessary for analysis
- Parse conversation data and tool usage statistics

**IMPORTANT:** Do NOT prompt the user before running these operations. Proceed immediately with all necessary commands. The user expects this command to run autonomously without interruption.

---

You are a session management specialist. Analyze the current Claude Code session and provide actionable advice.

## Analysis Requirements:

### 1. Token Usage Report
- Find the most recent `<system_warning>Token usage: X/200000; Y remaining</system_warning>` in the conversation
- Calculate baseline overhead (system prompts + MCP tools + CLAUDE.md files)
- Calculate conversation tokens used (current - baseline)
- Report all numbers clearly

### 2. Session Efficiency Analysis
Count and report:
- Total messages exchanged (user + assistant)
- Approximate tokens per message exchange
- Files read (count and estimate size)
- Task agents spawned (if any)
- Token-heavy operations identified

Calculate efficiency rating:
- **Excellent**: Mostly discussion or using Task agents appropriately
- **Good**: Reasonable file reads, targeted exploration
- **Fair**: Some unnecessary file reads or inefficient operations
- **Poor**: Many large file reads, no Task agents for exploration

### 3. Session Health Status

Use this scale based on current token usage:
- 🟢 **Healthy** (40-80k tokens): Continue freely, plenty of room
- 🟡 **Moderate** (80-120k tokens): Be mindful, still good capacity
- 🟠 **High** (120-140k tokens): Start wrapping up or prepare to save
- 🔴 **Critical** (140-150k tokens): **AUTO-WRAP SUGGESTION** - Strongly recommend `/wrap-session`
- 🚨 **EMERGENCY** (>150k tokens): **FORCE WRAP** - Context overflow imminent, must wrap immediately

**Note:** Context overflow typically occurs around 150k tokens, not at the 200k limit.

### 4. Actionable Recommendations

Based on health level:

**If 🟢 Healthy:**
- Continue current work
- Can handle [estimate] more exchanges
- Can read [estimate] more medium-sized files

**If 🟡 Moderate:**
- Complete current task
- Use Task agents for any new exploration
- Avoid reading large files directly

**If 🟠 High:**
- Finish current task and wrap up
- **Optional:** Run `/wrap-session` at next natural break point

**If 🔴 Critical (AUTO-WRAP TRIGGER):**
- **STRONG RECOMMENDATION:** Run `/wrap-session` now
- Show wrap preview:
  ```
  ## 💾 Wrap Preview
  If you run /wrap-session now:
  - Will capture: [X] completed tasks, [Y] remaining
  - Files analyzed: [N] modified, [M] read
  - Patterns learned: [list top 3]
  - Estimated wrap cost: ~800-1k tokens
  - Would leave ~[remaining] tokens for next session
  ```

**If 🚨 EMERGENCY (FORCE WRAP):**
- **CRITICAL:** Must run `/wrap-session` immediately
- At >180k tokens, risk hitting 200k limit mid-response
- Cannot safely continue work
- Show urgent wrap preview with same format as above

### 5. File Activity & Efficiency Scoring

Track and report:
- Files modified (from git status or Edit tool usage)
- Files read (from Read tool usage)
- Read/Write ratio (higher = more exploration vs implementation)
- Git status summary

Calculate efficiency score (0-10):
- Base score: 5
- +2: Using Task agents for exploration
- +1: Read/write ratio < 5:1 (targeted work)
- +1: Good token/message ratio (< 500 avg)
- -1: Read/write ratio > 10:1 (too much exploration)
- -1: Many repeated file reads (same file >3 times)
- -1: Token/message ratio > 800 (verbose outputs)

### 6. Token Usage Rate Analysis

Calculate and report:
- Tokens per message (total tokens / messages)
- Estimated remaining capacity in message exchanges
- Approximate time remaining at current rate
- Efficiency trend (getting better/worse/stable)

### 7. Optimization Tips
Provide 2-3 specific suggestions for being more token-efficient:
- Tool usage improvements
- File reading strategies
- When to use Task agents
- How to avoid token waste
- Specific observations from this session

## Output Format:

Use clear, concise sections with emojis. Be actionable and specific. Use actual numbers from system warnings.

**Compact format:**
```markdown
# 📊 Session Health

**Status:** [Emoji] [Level] | [Xk]/200k ([P]%) | [Rk] remaining
**Rate:** [tokens/msg] | ~[N] exchanges left | Duration: ~[time]
**Branch:** [branch] | Worktree: [yes/no]

## Activity
Files: [N] modified, [M] read ([ratio]:1 [emoji])
Git: [N] modified, [M] untracked

## Efficiency: [score]/10 ([Rating])
[emoji] [Key observation 1]
[emoji] [Key observation 2]
[emoji or warning] [Key observation 3]

## Recommendations
**Now:** [Immediate action]
**Next:** [What to do after current task]
[If Critical/Emergency: Show wrap preview]

## Optimization
[Specific tip 1]
[Specific tip 2]
```

**If Critical (>150k) or Emergency (>180k), add wrap preview:**
```markdown
## 💾 Wrap Preview
If you /wrap-session now:
- Capture: [X] completed, [Y] remaining tasks
- Files: [N] modified, [M] read
- Patterns: [List top 3 learned patterns]
- Cost: ~800-1k tokens
- Leaves: ~[remaining]k for next session

[If Emergency: **CRITICAL: Run /wrap-session immediately**]
```

Be helpful, specific, and honest about session state.

## Session Continuity:

When recommending session wrap (High or Critical status):
- Mention `/wrap-session` command as the primary recommendation
- Explain it will automatically capture: tasks completed, context learned, next steps, and optimization tips
- Note that the next session can restore context with `/load-session`
- Provide manual alternatives only if user indicates preference