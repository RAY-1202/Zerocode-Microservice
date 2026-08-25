export const apiPort = (pathname) =>
  pathname === '/api/user' || pathname.startsWith('/api/user/') ? 8124 : 8125
