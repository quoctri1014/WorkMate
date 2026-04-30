/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        "primary": "#1c6185",
        "primary-container": "#9ad6ff",
        "on-primary-container": "#004b6a",
        "secondary": "#396077",
        "secondary-container": "#bae2fe",
        "surface": "#f5f7f9",
        "surface-container-low": "#eef1f3",
        "surface-container-lowest": "#ffffff",
        "on-surface": "#2c2f31",
        "on-surface-variant": "#595c5e",
        "error": "#b31b25",
        "error-container": "#fb5151",
        // Dark Mode Colors
        "dark-bg": "#0f172a",
        "dark-card": "#1e293b",
        "dark-border": "#334155",
        "dark-text": "#f1f5f9"
      },
      fontFamily: {
        sans: ["Be Vietnam Pro", "sans-serif"],
      },
      borderRadius: {
        "2xl": "1.5rem",
        "3xl": "2rem",
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
