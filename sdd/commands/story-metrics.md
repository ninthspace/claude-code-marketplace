# /sdd:story-metrics

## Meta
- Version: 2.0
- Category: story-analysis
- Complexity: medium
- Purpose: Calculate and display development velocity, cycle time, and quality metrics from story data

## Definition
**Purpose**: Analyze completed and in-progress stories to understand development patterns, velocity trends, bottlenecks, and generate actionable insights.

**Syntax**: `/sdd:story-metrics [period]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| period | string | No | "all" | Time period to analyze (week, month, quarter, all) | One of: week, month, quarter, all |

## INSTRUCTION: Analyze Story Metrics

### INPUTS
- period: Optional time period filter (defaults to all-time)
- Story files from all directories:
  - `/stories/backlog/` - Stories not started
  - `/stories/development/` - Active stories
  - `/stories/review/` - Stories in review
  - `/stories/qa/` - Stories in testing
  - `/stories/completed/` - Finished stories

### PROCESS

#### Phase 1: Data Collection
1. **SCAN** all story directories for `.md` files
2. **PARSE** each story file to extract:
   - Story ID and title
   - Status (current folder)
   - Started date
   - Completed date
   - Stage transitions (from progress log)
   - Test results
   - Bug count (from progress log)
   - Story size (days to complete)
   - Technologies used (from technical notes)

3. **FILTER** by period if specified:
   - week: Last 7 days
   - month: Last 30 days
   - quarter: Last 90 days
   - all: All stories

4. **CALCULATE** time in each stage:
   - Development time
   - Review time
   - QA time
   - Total cycle time

#### Phase 2: Velocity Metrics
1. **COUNT** completed stories per time period
2. **CALCULATE** average cycle time (start to completion)
3. **COMPUTE** throughput (stories per week)
4. **GENERATE** trend analysis:
   - Group stories by week
   - Create visual bar chart
   - Calculate trend direction

5. **DISPLAY** velocity metrics:
   ```
   📈 VELOCITY METRICS
   ══════════════════════════════════

   Current Period: [Date range]
   - Stories completed: [count]
   - Average cycle time: [X] days
   - Throughput: [X] stories/week

   Trend (Last 4 Weeks):
   Week 1: ████████ 8 stories
   Week 2: ██████   6 stories
   Week 3: █████████ 9 stories
   Week 4: ███████  7 stories

   Status: [↗ Trending up | ↘ Trending down | → Stable]
   ```

#### Phase 3: Cycle Time Analysis
1. **CALCULATE** average time per stage:
   - Development: Mean days from start to review
   - Review: Mean hours from review to QA
   - QA: Mean hours from QA to completion
   - Total: Mean days from start to completion

2. **IDENTIFY** outliers:
   - Fastest story (min cycle time)
   - Slowest story (max cycle time)

3. **DETECT** bottlenecks:
   - Stage with longest average time
   - Stage with most variance

4. **DISPLAY** cycle time analysis:
   ```
   ⏱️  CYCLE TIME ANALYSIS
   ══════════════════════════════════

   Average by Stage:
   - Development: [X] days
   - Review: [X] hours
   - QA: [X] hours
   - Total: [X] days

   Outliers:
   - Fastest: [STORY-ID] - [X] days
   - Slowest: [STORY-ID] - [X] days

   Bottlenecks:
   - [Stage]: [X]% above average
   ```

#### Phase 4: Quality Metrics
1. **CALCULATE** first-time pass rate:
   - Stories completed without rework
   - Percentage of stories passing review first time

2. **COUNT** bugs by stage:
   - Average bugs found in review
   - Average bugs found in QA
   - Total production incidents

3. **ANALYZE** test coverage:
   - Average test cases per story
   - Percentage with complete test coverage

4. **COMPUTE** rollback rate:
   - Stories requiring rollback
   - Percentage of completed stories

5. **DISPLAY** quality metrics:
   ```
   🎯 QUALITY METRICS
   ══════════════════════════════════

   Pass Rate:
   - First-time pass: [X]%
   - Average rework cycles: [X]

   Bug Detection:
   - Avg bugs in review: [X]
   - Avg bugs in QA: [X]
   - Production incidents: [count]

   Testing:
   - Avg test cases: [X]
   - Coverage target met: [X]%

   Stability:
   - Rollback rate: [X]%
   ```

#### Phase 5: Story Size Distribution
1. **CATEGORIZE** stories by cycle time:
   - Small: 1-2 days
   - Medium: 3-5 days
   - Large: 5+ days

2. **CALCULATE** distribution percentages
3. **GENERATE** visual distribution chart
4. **PROVIDE** sizing recommendation

5. **DISPLAY** size distribution:
   ```
   📊 STORY SIZE DISTRIBUTION
   ══════════════════════════════════

   Small (1-2 days): ████████ 40% ([count] stories)
   Medium (3-5 days): ██████ 30% ([count] stories)
   Large (5+ days): ██████ 30% ([count] stories)

   Recommendation:
   [Break down large stories | Continue current sizing | Adjust estimation]
   ```

#### Phase 6: Technology Usage
1. **EXTRACT** technologies from technical notes
2. **COUNT** usage frequency across stories
3. **IDENTIFY** new technology additions
4. **TRACK** adoption dates

5. **DISPLAY** tech stack usage:
   ```
   🔧 TECH STACK USAGE
   ══════════════════════════════════

   Most Used:
   - [Technology]: [X] stories
   - [Framework]: [X] stories
   - [Library]: [X] stories

   Recent Additions:
   - [New Tech]: Added [date]
   - [New Tool]: Added [date]
   ```

#### Phase 7: Development Patterns
1. **ANALYZE** completion patterns:
   - Most productive day of week
   - Most productive time period
   - Average stories per week

2. **IDENTIFY** common blockers:
   - Extract from progress logs
   - Count blocker frequency
   - Categorize blocker types

3. **DISPLAY** development patterns:
   ```
   📋 DEVELOPMENT PATTERNS
   ══════════════════════════════════

   Productivity:
   - Most productive day: [Day]
   - Peak completion time: [Time range]
   - Avg stories/week: [X]

   Common Blockers:
   - [Blocker type]: [X] occurrences
   - [Blocker type]: [X] occurrences
   ```

#### Phase 8: Predictions
1. **CALCULATE** velocity-based projections:
   - Expected stories next week
   - Expected stories next month
   - Confidence interval

2. **ANALYZE** work-in-progress:
   - Current parallel stories
   - Optimal WIP limit based on data
   - Capacity recommendations

3. **DISPLAY** projections:
   ```
   🔮 PROJECTIONS
   ══════════════════════════════════

   At Current Velocity:
   - Next week: [X] stories (±[Y])
   - Next month: [X] stories (±[Y])

   Capacity:
   - Current WIP: [X] stories
   - Optimal WIP limit: [X] stories
   - Capacity utilization: [X]%
   ```

#### Phase 9: Recommendations
1. **ANALYZE** metrics for improvement opportunities
2. **GENERATE** specific, actionable recommendations:
   - Process optimizations
   - Bottleneck resolutions
   - Quality improvements
   - Tool suggestions

3. **PRIORITIZE** recommendations by impact

4. **DISPLAY** recommendations:
   ```
   💡 RECOMMENDATIONS
   ══════════════════════════════════

   High Impact:
   1. [Specific improvement with metric basis]
   2. [Process optimization with expected gain]
   3. [Tool suggestion with benefit]

   Quick Wins:
   - [Low-effort, high-value change]
   - [Simple process tweak]
   ```

#### Phase 10: Metrics Dashboard
1. **COMPILE** all metrics into summary dashboard
2. **CALCULATE** trend indicators:
   - Velocity: trending up/down/stable
   - Quality: improving/declining/stable
   - Efficiency: percentage improvement

3. **EXTRACT** top insights from data
4. **GENERATE** action items

5. **DISPLAY** complete dashboard:
   ```
   📊 METRICS DASHBOARD
   ══════════════════════════════════
   Period: [Date range]
   Generated: [Date and time]

   HEADLINES:
   • Velocity: [↗ Trending up | ↘ Trending down | → Stable] ([X]%)
   • Quality: [Improving | Declining | Stable] ([X]%)
   • Efficiency: [X]% [improvement | decline] over last period

   KEY INSIGHTS:
   • [Data-driven insight 1]
   • [Data-driven insight 2]
   • [Data-driven insight 3]

   ACTION ITEMS:
   • [Prioritized action 1]
   • [Prioritized action 2]

   NEXT REVIEW: [Suggested date]
   ```

6. **OFFER** export option:
   ```
   💾 Export metrics to /metrics/[date].md? (y/n)
   ```

### OUTPUTS
- Console display of all metric sections
- Optional: `/metrics/[date].md` - Saved metrics report with timestamp

### RULES
- MUST scan all story directories (backlog, development, review, qa, completed)
- MUST calculate accurate time periods from story dates
- MUST handle missing dates gracefully (exclude from time-based metrics)
- SHOULD provide visual representations (bar charts) where helpful
- SHOULD calculate trends over multiple periods
- SHOULD generate actionable recommendations
- NEVER modify story files (read-only operation)
- ALWAYS display metric sources (which stories contributed)
- ALWAYS include confidence levels for predictions
- MUST handle empty directories (no stories found)

## Dashboard Layout

```
📊 METRICS DASHBOARD
══════════════════════════════════════════════════════════════════
Period: [Start Date] to [End Date]
Generated: [Timestamp]

📈 VELOCITY METRICS
─────────────────────────────────────
Current Period:
- Stories completed: [count]
- Average cycle time: [X] days
- Throughput: [X] stories/week

Trend (Last 4 Weeks):
Week 1: ████████ 8 stories
Week 2: ██████   6 stories
Week 3: █████████ 9 stories
Week 4: ███████  7 stories

Status: ↗ Trending up (15%)

⏱️  CYCLE TIME ANALYSIS
─────────────────────────────────────
Average by Stage:
- Development: [X] days
- Review: [X] hours
- QA: [X] hours
- Total: [X] days

Outliers:
- Fastest: [STORY-ID] - [X] days
- Slowest: [STORY-ID] - [X] days

Bottlenecks:
- [Stage]: [X]% above average

🎯 QUALITY METRICS
─────────────────────────────────────
Pass Rate:
- First-time pass: [X]%
- Average rework cycles: [X]

Bug Detection:
- Avg bugs in review: [X]
- Avg bugs in QA: [X]
- Production incidents: [count]

Testing:
- Avg test cases: [X]
- Coverage target met: [X]%

Stability:
- Rollback rate: [X]%

📊 STORY SIZE DISTRIBUTION
─────────────────────────────────────
Small (1-2 days): ████████ 40% ([count])
Medium (3-5 days): ██████ 30% ([count])
Large (5+ days): ██████ 30% ([count])

Recommendation: [Sizing guidance]

🔧 TECH STACK USAGE
─────────────────────────────────────
Most Used:
- [Technology]: [X] stories
- [Framework]: [X] stories

Recent Additions:
- [New Tech]: Added [date]

📋 DEVELOPMENT PATTERNS
─────────────────────────────────────
Productivity:
- Most productive day: [Day]
- Peak completion time: [Time range]
- Avg stories/week: [X]

Common Blockers:
- [Blocker]: [X] occurrences

🔮 PROJECTIONS
─────────────────────────────────────
At Current Velocity:
- Next week: [X] stories (±[Y])
- Next month: [X] stories (±[Y])

Capacity:
- Current WIP: [X] stories
- Optimal WIP limit: [X]
- Utilization: [X]%

💡 RECOMMENDATIONS
─────────────────────────────────────
High Impact:
1. [Specific improvement]
2. [Process optimization]
3. [Tool suggestion]

Quick Wins:
- [Low-effort improvement]

══════════════════════════════════════════════════════════════════
```

## Examples

### Example 1: All-Time Metrics
```bash
INPUT:
/sdd:story-metrics

OUTPUT:
→ Scanning story directories...
→ Found 45 stories across all stages
→ Analyzing velocity, cycle time, and quality...

📊 METRICS DASHBOARD
══════════════════════════════════════════════════════════════════
Period: All Time (Jan 1, 2025 - Oct 1, 2025)
Generated: Oct 1, 2025 at 2:30 PM

📈 VELOCITY METRICS
─────────────────────────────────────
Current Period:
- Stories completed: 42
- Average cycle time: 4.2 days
- Throughput: 6.8 stories/week

Trend (Last 4 Weeks):
Week 1: ████████ 8 stories
Week 2: ██████   6 stories
Week 3: █████████ 9 stories
Week 4: ███████  7 stories

Status: ↗ Trending up (12%)

[Additional sections...]

💾 Export metrics to /metrics/2025-10-01.md? (y/n)
```

### Example 2: Monthly Metrics
```bash
INPUT:
/sdd:story-metrics month

OUTPUT:
→ Scanning story directories...
→ Found 28 stories in last 30 days
→ Analyzing September 2025 data...

📊 METRICS DASHBOARD
══════════════════════════════════════════════════════════════════
Period: Sep 1, 2025 - Sep 30, 2025
Generated: Oct 1, 2025 at 2:30 PM

📈 VELOCITY METRICS
─────────────────────────────────────
Current Period:
- Stories completed: 28
- Average cycle time: 3.8 days
- Throughput: 7.0 stories/week

Status: ↗ Trending up (18% vs August)

[Additional sections...]
```

### Example 3: No Stories Found
```bash
INPUT:
/sdd:story-metrics week

OUTPUT:
→ Scanning story directories...
→ No stories found in last 7 days

⚠️  INSUFFICIENT DATA
══════════════════════════════════════
No completed stories found in the specified period.

Suggestions:
- Try a longer period: /sdd:story-metrics month
- Check if stories are marked as completed
- Verify story dates are set correctly

Current WIP:
- Development: 2 stories
- Review: 1 story
- QA: 1 story
```

## Edge Cases

### No Completed Stories
- DETECT empty completed directory
- DISPLAY insufficient data message
- SHOW current WIP as context
- SUGGEST longer time period

### Missing Dates in Stories
- SKIP stories without started/completed dates
- LOG warning about incomplete data
- CALCULATE metrics from available data
- NOTE data quality issue in dashboard

### Single Story in Period
- CALCULATE limited metrics
- WARN about small sample size
- AVOID trend calculations
- PROVIDE useful context instead

### Inconsistent Story Format
- PARSE flexibly with fallbacks
- LOG parsing warnings
- EXTRACT what's available
- CONTINUE with best-effort analysis

## Error Handling
- **No story directories**: Report missing directories, suggest `/sdd:project-init`
- **Permission errors**: Report specific access issues
- **Malformed story files**: Skip problematic files, log warnings
- **Invalid period parameter**: Show valid options, use default
- **Zero stories**: Provide helpful guidance instead of empty metrics

## Performance Considerations
- Efficient file scanning (single pass per directory)
- Lazy date parsing (only for period-filtered stories)
- Cached calculations within single run
- Streaming output for large datasets
- Typical completion time: < 2 seconds for 100 stories

## Related Commands
- `/sdd:story-patterns` - Identify recurring patterns in stories
- `/sdd:story-tech-debt` - Analyze technical debt from stories
- `/sdd:project-status` - View current story statuses
- `/sdd:story-list` - List stories with filters

## Constraints
- ✅ MUST be read-only (no file modifications)
- ✅ MUST handle missing/malformed data gracefully
- ✅ MUST provide accurate calculations
- ⚠️ SHOULD visualize trends with charts
- 📊 SHOULD include confidence intervals for predictions
- 💡 SHOULD generate actionable recommendations
- 🔍 MUST show data sources for transparency
- ⏱️ MUST complete analysis in reasonable time (< 5s)
