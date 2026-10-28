export type MediaKind = 'image' | 'video'
export type MediaAccess = 'public' | 'private'

export interface MediaDefinition {
  readonly kind: MediaKind
  readonly access: MediaAccess
  readonly fallbackSrc: string
  readonly publicSrc?: string
}

export type PrivateMediaUrlProvider = (mediaId: string) => Promise<string | null>
