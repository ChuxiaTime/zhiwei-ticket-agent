export const faultTypeLabels = {
  network: '网络',
  hardware: '硬件',
  software: '软件',
  account: '账号',
  unknown: '未识别',
}

export function formatFaultType(value) {
  return faultTypeLabels[value] || value || '未识别'
}

export function formatTime(value) {
  if (!value) return '-'
  return String(value).replace('T', ' ').slice(0, 19)
}

export function formatScore(value) {
  const score = Number(value)
  return Number.isFinite(score) ? score.toFixed(3) : '-'
}

export function cleanSuggestion(value) {
  const text = String(value || '').replace(/^初步排查建议[:：]\s*/, '')
  return text || '暂无建议'
}
