#!/bin/bash

# Update Tailwind Config
cat > /opt/thanks/frontend/tailwind.config.js << 'EOF'
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
EOF

# Update index.css
cat > /opt/thanks/frontend/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    margin: 0;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    @apply bg-luxury-charcoal text-luxury-cream;
  }

  * {
    @apply scrollbar-thin scrollbar-track-transparent scrollbar-thumb-luxury-gold/20;
  }
}

@layer components {
  /* Glass Card Component */
  .glass-card {
    @apply bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl shadow-glass;
  }

  .glass-card-hover {
    @apply glass-card transition-all duration-300 hover:bg-white/8 hover:border-white/20 hover:shadow-luxury;
  }

  /* Premium Button */
  .btn-luxury {
    @apply relative overflow-hidden px-8 py-3 rounded-xl font-semibold tracking-wide;
    @apply bg-gradient-to-r from-luxury-gold via-luxury-gold-light to-luxury-gold;
    @apply text-luxury-charcoal shadow-luxury transition-all duration-300;
    @apply hover:shadow-luxury hover:scale-105 active:scale-95;
  }

  .btn-glass {
    @apply px-6 py-3 rounded-xl font-medium backdrop-blur-md;
    @apply bg-white/10 border border-white/20 text-white;
    @apply hover:bg-white/15 hover:border-white/30 transition-all duration-300;
    @apply shadow-glass-sm hover:shadow-glass;
  }

  .btn-outline-gold {
    @apply px-6 py-3 rounded-xl font-medium border-2 border-luxury-gold;
    @apply text-luxury-gold hover:bg-luxury-gold hover:text-luxury-charcoal;
    @apply transition-all duration-300 shadow-inner-glass;
  }

  /* Input Fields */
  .input-glass {
    @apply w-full px-4 py-3 rounded-xl backdrop-blur-md;
    @apply bg-white/5 border border-white/10 text-luxury-cream;
    @apply placeholder:text-white/40 focus:outline-none;
    @apply focus:bg-white/10 focus:border-luxury-gold/50;
    @apply transition-all duration-300 shadow-inner-glass;
  }

  /* Animated Background */
  .bg-luxury-pattern {
    @apply bg-luxury-gradient relative overflow-hidden;
  }

  .bg-luxury-pattern::before {
    content: '';
    @apply absolute inset-0 opacity-5;
    background-image:
      radial-gradient(circle at 20% 50%, rgba(212, 175, 55, 0.1) 0%, transparent 50%),
      radial-gradient(circle at 80% 80%, rgba(212, 175, 55, 0.1) 0%, transparent 50%),
      radial-gradient(circle at 40% 20%, rgba(244, 228, 176, 0.05) 0%, transparent 50%);
    animation: float 20s ease-in-out infinite;
  }

  /* Section Header */
  .section-title {
    @apply text-3xl md:text-4xl font-bold mb-2;
    @apply bg-gradient-to-r from-luxury-gold via-luxury-gold-light to-luxury-gold;
    @apply bg-clip-text text-transparent;
  }

  /* Glass Divider */
  .glass-divider {
    @apply h-px bg-gradient-to-r from-transparent via-white/20 to-transparent my-6;
  }

  /* Status Badge */
  .badge-glass {
    @apply inline-flex items-center px-3 py-1 rounded-full text-xs font-medium;
    @apply backdrop-blur-md bg-white/10 border border-white/20;
  }

  /* Card with shimmer effect */
  .card-shimmer {
    @apply relative overflow-hidden;
  }

  .card-shimmer::after {
    content: '';
    @apply absolute inset-0 translate-x-full;
    background: linear-gradient(
      90deg,
      rgba(255, 255, 255, 0) 0%,
      rgba(255, 255, 255, 0.1) 50%,
      rgba(255, 255, 255, 0) 100%
    );
    animation: shimmer 3s infinite;
  }

  /* Luxury Scrollbar */
  .luxury-scroll::-webkit-scrollbar {
    @apply w-2;
  }

  .luxury-scroll::-webkit-scrollbar-track {
    @apply bg-transparent;
  }

  .luxury-scroll::-webkit-scrollbar-thumb {
    @apply bg-luxury-gold/30 rounded-full;
  }

  .luxury-scroll::-webkit-scrollbar-thumb:hover {
    @apply bg-luxury-gold/50;
  }
}

@layer utilities {
  .text-shadow-glow {
    text-shadow: 0 0 10px rgba(212, 175, 55, 0.3);
  }

  .glass-blur-strong {
    backdrop-filter: blur(24px) saturate(180%);
  }

  .glass-blur-medium {
    backdrop-filter: blur(16px) saturate(150%);
  }

  .glass-blur-light {
    backdrop-filter: blur(8px) saturate(120%);
  }
}
EOF

echo "✅ Design files updated successfully!"
