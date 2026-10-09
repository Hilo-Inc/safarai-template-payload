import type { MetadataRoute } from 'next'

import { getServerSideURL } from '@/utilities/getURL'

export const dynamic = 'force-dynamic'

export default function robots(): MetadataRoute.Robots {
  const url = getServerSideURL()
  return {
    rules: { userAgent: '*', disallow: '/admin/' },
    sitemap: [`${url}/pages-sitemap.xml`, `${url}/posts-sitemap.xml`],
  }
}
