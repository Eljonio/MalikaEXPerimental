/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        glass: {
          light: 'rgba(255, 255, 255, 0.1)',
          medium: 'rgba(255, 255, 255, 0.05)',
          dark: 'rgba(0, 0, 0, 0.2)',
          border: 'rgba(255, 255, 255, 0.18)',
        },
        luxury: {
          gold: '#D4AF37',
          'gold-light': '#F4E4B0',
          'gold-dark': '#B8941E',
          charcoal: '#1a1a1a',
          'charcoal-light': '#2a2a2a',
          cream: '#FAF9F6',
          bronze: '#CD7F32',
        }
      },
      backdropBlur: {
        xs: '2px',
      },
      backgroundImage: {
        'luxury-gradient': 'linear-gradient(135deg, #1a1a1a 0%, #2a2a2a 100%)',
        'glass-gradient': 'linear-gradient(135deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0.05) 100%)',
        'gold-gradient': 'linear-gradient(135deg, #D4AF37 0%, #F4E4B0 50%, #D4AF37 100%)',
      },
      boxShadow: {
        'glass': '0 8px 32px 0 rgba(0, 0, 0, 0.37)',
        'glass-sm': '0 4px 16px 0 rgba(0, 0, 0, 0.25)',
        'luxury': '0 10px 40px rgba(212, 175, 55, 0.15)',
        'inner-glass': 'inset 0 2px 4px 0 rgba(255, 255, 255, 0.06)',
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'shimmer': 'shimmer 2s linear infinite',
        'glow': 'glow 2s ease-in-out infinite alternate',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-1000px 0' },
          '100%': { backgroundPosition: '1000px 0' },
        },
        glow: {
          '0%': { boxShadow: '0 0 5px rgba(212, 175, 55, 0.2), 0 0 10px rgba(212, 175, 55, 0.1)' },
          '100%': { boxShadow: '0 0 10px rgba(212, 175, 55, 0.4), 0 0 20px rgba(212, 175, 55, 0.2)' },
        },
      },
    },
  },
  plugins: [],
}
