
Below are low-fidelity wireframes (screen-by-screen layouts)

These are intentionally **simple, structural, and precise**.

# 1. Onboarding Flow (4 Screens)

## Screen 1: Welcome / Philosophy


```
[Soft Gradient Background]

Life Intelligence OS

A quiet space to reflect,

notice patterns, and understand

yourself over time.

[ Begin → ]
```


**Notes:**

- No feature explanation
- Emotional entry point, not functional

## Screen 2: Why Are You Here?

```

[Back]

What brings you here?

[ Text Input Box ]

------------------------------------

| I want more clarity in my life... |

------------------------------------

[ Continue → ]

```

**Notes:**

- Large input box
- Placeholder text soft, not directive

## Screen 3: Emotional Style

```

[Back]

How do you usually process emotions?

( ) I think through them quietly

( ) I talk them out

( ) I write them out

( ) I tend to avoid them

( ) I'm not sure

[ Continue → ]

```

## Screen 4: Tone Preference

```

[Back]

How would you like this space to feel?

( ) Quiet and grounding

( ) Soft and poetic

( ) Clear and simple

( ) Slightly analytical

[ Enter the space → ]

```

# 2. Daily Check-In Screen (Core UX)

## Main Screen Layout

```

[Date: Tuesday, March 12]

How was today?

Mood

------------------------------------

[   😐 --- 😌 --- 😊 --- 😄   ]  (Slider)

------------------------------------

Energy

------------------------------------

[   Low --- Medium --- High   ]  (Slider)

------------------------------------

One word for today

------------------------------------

| [ focused__________ ]       |

------------------------------------

What mattered today?

------------------------------------

| Today I spent time thinking |

| about...                    |

|                             |

------------------------------------

[ + Add voice note (optional) ]

[ Save Entry ]

```

**UX Notes:**

- Everything on **one scroll**
- No tabs
- No distractions
- “Save Entry” becomes active when input starts

## 3. Weekly Mirror Screen (Most Important)

## Weekly Reflection View

```

[Week of March 10–16]

Your week, reflected

------------------------------------

This week felt slightly uneven,

with moments of clarity early on

giving way to a heavier middle.

You mentioned pressure a few times,

especially around work-related

situations, and your energy dipped

noticeably midweek.

By the weekend, there was a shift

toward something lighter — a sense

of space returning, even if briefly.

There’s a quiet pattern of pushing

through, even when energy is low.

------------------------------------

[ Did this feel accurate? ]

( Yes ) ( Somewhat ) ( No )

```

**Design Notes:**

- Full-screen reading
- No charts dominating
- Feels like reading a letter
- Typography is key

# 4. History / Timeline

## Weekly Cards View

```

Your reflections

------------------------------------

[ Week of March 10–16 ]

Soft, slightly heavy week with a

midweek dip in energy...

[ Mood Color Strip ]

------------------------------------

[ Week of March 3–9 ]

More stable and outwardly focused,

with consistent energy...

[ Mood Color Strip ]

------------------------------------

[ Week of Feb 24–March 2 ]

A quieter, more reflective period...

[ Mood Color Strip ]

```

**Notes:**

- Tap → opens full Weekly Mirror
- Color strip = subtle emotional memory

## 5. Minimal Home State (Returning User)

## Home / Entry Point

```

Good evening

Ready to reflect?

[ Start Today’s Entry ]

------------------------------------

Last week

A steady but slightly pressured week...

[ Read Reflection → ]

```

**Notes:**

- No dashboard
- No stats
- Just 2 actions:
    - Reflect today
    - Read last week

# 6. Settings / Privacy

## Settings Screen

```

Settings

------------------------------------

Notifications

[ Toggle ON/OFF ]

------------------------------------

Your Data

[ Export my reflections → ]

------------------------------------

Privacy

Your entries are private.

We do not sell or share your data.

[ Learn more → ]


```

# Navigation Model (Important)

Keep it extremely simple:

No bottom tabs

Flow:

```
Home

↓

Daily Entry

↓

Weekly Mirror

↓

History (accessible from home or mirror)

```

Optional:

- Swipe gestures between weeks

# Final UX Principles (Non-Negotiable)

- Every screen should feel like **a pause**
- No screen should feel like **a task**
- Reduce decisions → increase reflection
- Remove anything that feels like:
    - tracking
    - optimizing
    - performing