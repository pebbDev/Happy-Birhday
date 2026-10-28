export type InvitationAsset = {
  /** Unique, stable ID for a reusable artwork file (not a layout placement). */
  id: string
  /** Human-readable purpose, separate from accessible image alt text. */
  description: string
  /** Public asset path used by renderers. */
  src: string
}

export type SceneMotion =
  'sway-left' | 'sway-right' | 'sway-bloom' | 'sway-envelope' | 'petal-a' | 'petal-b' | 'petal-c'

export type SceneFrame = {
  x: number
  y: number
  width: number
  height: number
}

export type SceneLayer = {
  /** Stable app-owned identifier, independent from Figma's node ID. */
  id: string
  /** Traceable Figma node reference, retained for visual verification. */
  figmaNodeId: string
  /** Developer-facing visual intent; decorative images still use empty alt. */
  description: string
  src: string
  frame: SceneFrame
  plane: 'background' | 'foreground'
  responsiveClass?: string
  motionOriginClass?: string
  blur?: number
  priority?: boolean
  fetchPriority?: 'high' | 'low' | 'auto'
  motion?: SceneMotion
}

export type InvitationLetterContent = {
  openAriaLabel: string
  teaserLines: readonly string[]
  title: string
  note: string
  greeting: string
  paragraphs: readonly string[]
  signatureLines: readonly string[]
}

export type InvitationHeroCardProps = {
  name: string
  age: number
  taglineLines: readonly string[]
  holdLabel: string
  parchmentSrc: string
  cardFlowerSrc: string
  crownSrc: string
}

export type InvitationHeroCardEmits = { enter: [] }

export type InvitationPolaroidProps = {
  src: string
  alt: string
  frameSrc: string
  caption: string
}

export type InvitationArtLayersProps = {
  layers: readonly SceneLayer[]
  priorityLoading?: boolean
}

export type BrotherLetterProps = { letter: InvitationLetterContent }

export type HoldToEnterProps = { label: string }
export type HoldToEnterEmits = { completed: [] }
