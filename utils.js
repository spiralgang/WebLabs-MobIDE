export function androidCompatCheck() {
  let ua = navigator.userAgent;
  return /Android 10|aarch64|arm64|Linux/.test(ua);
}