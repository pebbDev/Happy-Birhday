import type { InvitationAsset, SceneLayer } from '../types/invitation.types'

// Public reusable artwork. Asset IDs identify files; scene-layer IDs identify placements.
// Descriptions explain visual intent to developers, not image alt text.
export const INVITATION_ASSETS = {
  landscape: {
    id: 'painted-landscape-background',
    description: 'Full-width painted landscape behind the invitation card',
    src: '/backgrounds/invitation/hero-landscape.webp',
  },
  foregroundRocks: {
    id: 'painted-rocks-overlay',
    description: 'Painted rocks and hillside overlay framing the lower landscape',
    src: '/backgrounds/invitation/foreground-rocks-overlay.webp',
  },
  foregroundLeft: {
    id: 'left-foreground-floral',
    description: 'Large floral artwork along the left foreground',
    src: '/backgrounds/invitation/foreground-left-floral.webp',
  },
  sakuraLeft: {
    id: 'sakura-branch-left',
    description: 'Sakura branch illustration framing the upper-left corner',
    src: '/ornaments/flowers/sakura-branch-top-left.webp',
  },
  sakuraRight: {
    id: 'sakura-branch-right',
    description: 'Sakura branch illustration framing the upper-right corner',
    src: '/ornaments/flowers/sakura-branch-top-right.webp',
  },
  cardFlower: {
    id: 'sakura-card-cluster',
    description: 'Sakura flower cluster attached to the central invitation card',
    src: '/ornaments/flowers/card-sakura-cluster.webp',
  },
  softFlower: {
    id: 'soft-foreground-blossom',
    description: 'Soft blossom reused in multiple decorative layer placements',
    src: '/ornaments/flowers/foreground-blossom-soft.webp',
  },
  cornerFlower: {
    id: 'flower-right-bottom-corner',
    description: 'Flower ornament decorating the lower-right edge',
    src: '/ornaments/flowers/corner-flower-right-bottom.webp',
  },
  smallBlossom: {
    id: 'small-blossom-accent',
    description: 'Small blossom reused near the paper card and lower scene',
    src: '/ornaments/flowers/small-blossom-left-bottom.webp',
  },
  cardSideFlower: {
    id: 'card-side-flower',
    description: 'Compact floral ornament bordering the side of the paper card',
    src: '/ornaments/flowers/card-side-flower.webp',
  },
  polaroidFlower: {
    id: 'polaroid-flower-accent',
    description: 'Flower illustration used beside the Polaroid artwork',
    src: '/ornaments/flowers/polaroid-flower.webp',
  },
  blurredFlower: {
    id: 'blurred-foreground-flower',
    description: 'Soft-focus flower used to create foreground depth',
    src: '/ornaments/flowers/foreground-flower-blurred.webp',
  },
  crown: {
    id: 'decorative-crown',
    description: 'Crown icon displayed above the recipient name',
    src: '/icons/invitation-crown.webp',
  },
  petalPink: {
    id: 'pink-petal-particle',
    description: 'Pink petal artwork reused in drifting particle layers',
    src: '/particles/petals/figma-petal-pink.webp',
  },
  petalPeach: {
    id: 'peach-petal-particle',
    description: 'Peach-toned petal artwork for floating decoration',
    src: '/particles/petals/figma-petal-peach.webp',
  },
  parchment: {
    id: 'invitation-parchment-paper',
    description: 'Illustrated paper backdrop behind the central invitation message',
    src: '/illustrations/objects/invitation-parchment.webp',
  },
  polaroid: {
    id: 'polaroid-picture-frame',
    description: 'Illustrated Polaroid frame layered over the recipient photo',
    src: '/frames/polaroid/invitation-polaroid.webp',
  },
} as const satisfies Record<string, InvitationAsset>
// Desktop Figma artboard size. Pixel frames are converted to percentage by InvitationArtLayers.
export const INVITATION_SCENE_SIZE = { width: 1672, height: 941 } as const

// Every layer owns its identity, original Figma node, purpose, frame and responsive override.
// The array order is the Figma paint order within each background/foreground plane.
// Keep Tailwind utility strings literal for static scanning.
export const INVITATION_LAYERS = [
  {
    id: 'hero-landscape',
    figmaNodeId: '184:57',
    description: 'Full-bleed painted landscape behind the invitation card',
    src: INVITATION_ASSETS.landscape.src,
    frame: { x: 0, y: 0, width: 1672, height: 941 },
    plane: 'background',
    priority: true,
    fetchPriority: 'high',
    responsiveClass: 'h-full w-full max-[600px]:object-[60%_center]',
  },
  {
    id: 'sakura-top-left',
    figmaNodeId: '184:61',
    description: 'Large sakura branch framing the hero from the upper left',
    src: INVITATION_ASSETS.sakuraLeft.src,
    frame: { x: -75, y: -112, width: 687, height: 516 },
    plane: 'background',
    priority: true,
    motion: 'sway-left',
    motionOriginClass: 'origin-[20%_0]',
    responsiveClass:
      'max-[600px]:left-[-24%] max-[600px]:top-[-3%] max-[600px]:h-auto max-[600px]:w-[89%]',
  },
  {
    id: 'foreground-rocks',
    figmaNodeId: '184:64',
    description: 'Painted rock and hillside overlay across the lower landscape',
    src: INVITATION_ASSETS.foregroundRocks.src,
    frame: { x: 0, y: -174, width: 1672, height: 1254 },
    plane: 'background',
    priority: true,
    responsiveClass:
      'max-[600px]:top-auto max-[600px]:bottom-0 max-[600px]:h-[40%] max-[600px]:w-full max-[600px]:object-bottom',
  },
  {
    id: 'soft-blossom-right-front',
    figmaNodeId: '196:160',
    description: 'Soft blurred blossom at the lower right foreground',
    src: INVITATION_ASSETS.softFlower.src,
    frame: { x: 1432, y: 757, width: 342, height: 342 },
    plane: 'foreground',
    blur: 5.3,
    responsiveClass:
      'max-[600px]:top-auto max-[600px]:bottom-[-5%] max-[600px]:left-auto max-[600px]:right-[-16%] max-[600px]:h-auto max-[600px]:w-[35%]',
  },
  {
    id: 'soft-blossom-left',
    figmaNodeId: '186:78',
    description: 'Small floating blossom on the left side of the scene',
    src: INVITATION_ASSETS.softFlower.src,
    frame: { x: -32, y: 194, width: 138, height: 138 },
    plane: 'background',
    motion: 'sway-bloom',
    motionOriginClass: 'origin-[30%_12%]',
    responsiveClass:
      'max-[600px]:top-[17%] max-[600px]:left-[-4%] max-[600px]:h-auto max-[600px]:w-[20%]',
  },
  {
    id: 'corner-flower-right-front',
    figmaNodeId: '189:103',
    description: 'Flower cluster in front of the lower right envelope',
    src: INVITATION_ASSETS.cornerFlower.src,
    frame: { x: 1547, y: 752, width: 189, height: 189 },
    plane: 'foreground',
    motion: 'sway-envelope',
    motionOriginClass: 'origin-[80%_80%]',
    responsiveClass:
      'max-[600px]:top-auto max-[600px]:bottom-[-5%] max-[600px]:left-auto max-[600px]:right-[-16%] max-[600px]:h-auto max-[600px]:w-[35%]',
  },
  {
    id: 'small-blossom-lower-left',
    figmaNodeId: '190:109',
    description: 'Small sakura near the lower left of the paper card',
    src: INVITATION_ASSETS.smallBlossom.src,
    frame: { x: 380, y: 786, width: 100, height: 100 },
    plane: 'background',
    responsiveClass: 'max-[600px]:hidden',
  },
  {
    id: 'pink-petal-center',
    figmaNodeId: '191:115',
    description: 'Pink drifting petal above the central card',
    src: INVITATION_ASSETS.petalPink.src,
    frame: { x: 613, y: 305, width: 99, height: 99 },
    plane: 'background',
    motion: 'petal-a',
  },
  {
    id: 'peach-petal-left',
    figmaNodeId: '191:118',
    description: 'Peach drifting petal to the left of the central card',
    src: INVITATION_ASSETS.petalPeach.src,
    frame: { x: 246, y: 531, width: 85, height: 85 },
    plane: 'background',
    motion: 'petal-b',
  },
  {
    id: 'flower-card-side',
    figmaNodeId: '195:144',
    description: 'Small flower attached to the lower side of the paper card',
    src: INVITATION_ASSETS.cardSideFlower.src,
    frame: { x: 1107, y: 541, width: 64, height: 64 },
    plane: 'background',
    responsiveClass: 'max-[600px]:hidden',
  },
  {
    id: 'small-blossom-lower-center',
    figmaNodeId: '195:149',
    description: 'Blurred small blossom near the bottom center',
    src: INVITATION_ASSETS.smallBlossom.src,
    frame: { x: 941, y: 826, width: 106, height: 106 },
    plane: 'background',
    blur: 2.55,
    responsiveClass: 'max-[600px]:hidden',
  },
  {
    id: 'soft-blossom-bottom-front',
    figmaNodeId: '196:165',
    description: 'Soft blossom overlay in front of the bottom center',
    src: INVITATION_ASSETS.softFlower.src,
    frame: { x: 549, y: 727, width: 179, height: 179 },
    plane: 'foreground',
    responsiveClass:
      'max-[600px]:top-auto max-[600px]:bottom-[11%] max-[600px]:left-[29%] max-[600px]:h-auto max-[600px]:w-[17%]',
  },
  {
    id: 'flower-polaroid-side',
    figmaNodeId: '195:154',
    description: 'Accent flower overlapping the Polaroid artwork',
    src: INVITATION_ASSETS.polaroidFlower.src,
    frame: { x: 399, y: 398, width: 100, height: 100 },
    plane: 'background',
    responsiveClass: 'max-[600px]:hidden',
  },
  {
    id: 'floral-overlay-left-front',
    figmaNodeId: '186:95',
    description: 'Tall floral overlay covering the lower left foreground',
    src: INVITATION_ASSETS.foregroundLeft.src,
    frame: { x: 0, y: 276, width: 532, height: 665 },
    plane: 'foreground',
    responsiveClass:
      'max-[600px]:top-auto max-[600px]:bottom-[-8%] max-[600px]:left-[-28%] max-[600px]:h-auto max-[600px]:w-[60%]',
  },
  {
    id: 'blurred-flower-bottom-right-front',
    figmaNodeId: '196:173',
    description: 'Blurred floral highlight toward the lower right foreground',
    src: INVITATION_ASSETS.blurredFlower.src,
    frame: { x: 1062, y: 797, width: 238, height: 238 },
    plane: 'foreground',
    blur: 4.05,
    responsiveClass: 'max-[600px]:hidden',
  },
  {
    id: 'pink-petal-right',
    figmaNodeId: '196:176',
    description: 'Pink drifting petal near the right edge of the hero',
    src: INVITATION_ASSETS.petalPink.src,
    frame: { x: 1406, y: 304, width: 94, height: 94 },
    plane: 'background',
    motion: 'petal-c',
  },
  {
    id: 'sakura-top-right',
    figmaNodeId: '196:179',
    description: 'Decorative sakura branch framing the upper right corner',
    src: INVITATION_ASSETS.sakuraRight.src,
    frame: { x: 1479, y: -28, width: 257, height: 257 },
    plane: 'background',
    motion: 'sway-right',
    motionOriginClass: 'origin-[83%_0]',
    responsiveClass:
      'max-[600px]:left-[70%] max-[600px]:top-[-2%] max-[600px]:h-auto max-[600px]:w-[49%]',
  },
] as const satisfies readonly SceneLayer[]
