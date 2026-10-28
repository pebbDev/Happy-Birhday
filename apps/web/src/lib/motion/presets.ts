/**
 * Library-first motion presets. Rendering uses motion-v, not CSS @keyframes.
 * Keep artistic layout in Tailwind; use this module for reusable movement.
 */
export const SCENE_MOTION_PRESETS = {
  'sway-left': {
    initial: { rotate: -1.5, y: -3 },
    animate: { rotate: 2.4, y: 5 },
    transition: {
      duration: 6.5,
      ease: 'easeInOut' as const,
      repeat: Infinity,
      repeatType: 'reverse' as const,
    },
  },
  'sway-right': {
    initial: { rotate: 1.5, y: -2 },
    animate: { rotate: -3, y: 4 },
    transition: {
      duration: 7,
      ease: 'easeInOut' as const,
      repeat: Infinity,
      repeatType: 'reverse' as const,
    },
  },
  'sway-bloom': {
    initial: { rotate: -7, x: -4, y: -3 },
    animate: { rotate: 7, x: 7, y: 6 },
    transition: {
      duration: 5.7,
      ease: 'easeInOut' as const,
      repeat: Infinity,
      repeatType: 'reverse' as const,
    },
  },
  'sway-envelope': {
    initial: { rotate: -5, x: -3, y: -2 },
    animate: { rotate: 5, x: 3, y: 3 },
    transition: {
      duration: 5.4,
      ease: 'easeInOut' as const,
      repeat: Infinity,
      repeatType: 'reverse' as const,
    },
  },
  'petal-a': {
    initial: { x: 0, y: '-9vh', rotate: -20, opacity: 0 },
    animate: { x: [0, 40], y: ['-9vh', '40vh'], rotate: [-20, 160], opacity: [0, 0.95, 0.9, 0] },
    transition: {
      duration: 10,
      ease: 'easeInOut' as const,
      repeat: Infinity,
      times: [0, 0.15, 0.8, 1],
    },
  },
  'petal-b': {
    initial: { x: 0, y: '-8vh', rotate: -20, opacity: 0 },
    animate: { x: [0, -55], y: ['-8vh', '35vh'], rotate: [-20, 195], opacity: [0, 0.95, 0.95, 0] },
    transition: {
      duration: 11.4,
      ease: 'easeInOut' as const,
      repeat: Infinity,
      times: [0, 0.12, 0.75, 1],
    },
  },
  'petal-c': {
    initial: { x: 0, y: '-12vh', rotate: -30, opacity: 0 },
    animate: { x: [0, -100], y: ['-12vh', '36vh'], rotate: [-30, 180], opacity: [0, 1, 0.86, 0] },
    transition: {
      duration: 12,
      ease: 'easeInOut' as const,
      repeat: Infinity,
      times: [0, 0.1, 0.8, 1],
    },
  },
}

export const CROWN_GLOW = {
  initial: { opacity: 0.6, filter: 'drop-shadow(var(--shadow-ornament-glow-base))' },
  animate: {
    opacity: 1,
    filter:
      'drop-shadow(var(--shadow-ornament-glow-bright)) drop-shadow(var(--shadow-ornament-glow-warm))',
  },
  transition: {
    duration: 3.3,
    ease: 'easeInOut' as const,
    repeat: Infinity,
    repeatType: 'reverse' as const,
  },
} as const
