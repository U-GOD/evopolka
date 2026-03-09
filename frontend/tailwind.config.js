/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "primary": "#f4259d",
        "background-light": "#f8f5f7",
        "background-dark": "#0a0a0f",
        "accent-cyan": "#00f5ff",
        "accent-indigo": "#4338ca",
        "surface": "#161622",
        "border-muted": "#2d2d3d"
      },
      fontFamily: {
        "display": ["Space Grotesk"],
        "mono": ["ui-monospace", "SFMono-Regular", "Menlo", "Monaco", "Consolas", "Liberation Mono", "Courier New", "monospace"]
      },
      gridTemplateColumns: {
        '20': 'repeat(20, minmax(0, 1fr))',
      },
      gridTemplateRows: {
        '20': 'repeat(20, minmax(0, 1fr))',
      }
    },
  },
  plugins: [
    require('@tailwindcss/container-queries')
  ],
}
