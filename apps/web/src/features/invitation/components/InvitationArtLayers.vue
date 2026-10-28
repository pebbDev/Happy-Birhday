<script setup lang="ts">
import { motion, useReducedMotion } from 'motion-v'
import { SCENE_MOTION_PRESETS } from '@/lib/motion/presets'
import { INVITATION_SCENE_SIZE } from '../constants/invitation.constants'
import type { InvitationArtLayersProps, SceneLayer } from '../types/invitation.types'

defineProps<InvitationArtLayersProps>()

const prefersReducedMotion = useReducedMotion()

function layerStyle(layer: SceneLayer) {
  return {
    '--scene-x': (layer.frame.x / INVITATION_SCENE_SIZE.width) * 100 + '%',
    '--scene-y': (layer.frame.y / INVITATION_SCENE_SIZE.height) * 100 + '%',
    '--scene-w': (layer.frame.width / INVITATION_SCENE_SIZE.width) * 100 + '%',
    '--scene-h': (layer.frame.height / INVITATION_SCENE_SIZE.height) * 100 + '%',
    filter: layer.blur ? 'blur(' + layer.blur + 'px)' : undefined,
  }
}
</script>

<template>
  <motion.img
    v-for="layer in layers"
    :key="layer.id"
    :src="layer.src"
    :data-figma-node="layer.figmaNodeId"
    :style="layerStyle(layer)"
    :initial="
      layer.motion && !prefersReducedMotion ? SCENE_MOTION_PRESETS[layer.motion].initial : false
    "
    :animate="
      layer.motion && !prefersReducedMotion ? SCENE_MOTION_PRESETS[layer.motion].animate : undefined
    "
    :transition="
      layer.motion && !prefersReducedMotion
        ? SCENE_MOTION_PRESETS[layer.motion].transition
        : undefined
    "
    :class="[
      layer.motion ? 'invitation-scene-layer--' + layer.motion : undefined,
      layer.motionOriginClass,
      layer.responsiveClass,
      'pointer-events-none absolute left-[var(--scene-x)] top-[var(--scene-y)] h-[var(--scene-h)] w-[var(--scene-w)] select-none object-cover',
    ]"
    :loading="priorityLoading ? (layer.priority ? 'eager' : 'lazy') : undefined"
    :fetchpriority="priorityLoading ? layer.fetchPriority : undefined"
    class="invitation-scene-layer"
    aria-hidden="true"
    alt=""
    draggable="false"
  />
</template>
