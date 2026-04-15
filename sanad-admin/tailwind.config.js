import defaultTheme from 'tailwindcss/defaultTheme';
import forms from '@tailwindcss/forms';
import preset from './vendor/filament/filament/tailwind.config.preset';

/** @type {import('tailwindcss').Config} */
export default {
    presets: [preset],
    content: [
        './app/Filament/**/*.php',
        './resources/views/**/*.blade.php',
        './vendor/filament/**/*.blade.php',
    ],
    darkMode: 'class',
    theme: {
        extend: {
            fontFamily: {
                sans: ['Inter', ...defaultTheme.fontFamily.sans],
            },
            colors: {
                // Match Flutter AppColors
                primary: {
                    50: '#eff6ff',
                    100: '#dbeafe',
                    200: '#bfdbfe',
                    300: '#93c5fd',
                    400: '#60a5fa',
                    500: '#4A90D9', // Flutter AppColors.primary
                    600: '#3b82f6',
                    700: '#2563eb',
                    800: '#1d4ed8',
                    900: '#1e3a5f',
                    950: '#172554',
                },
                glass: {
                    light: 'rgba(255, 255, 255, 0.05)',
                    medium: 'rgba(255, 255, 255, 0.08)',
                    heavy: 'rgba(255, 255, 255, 0.12)',
                },
                surface: {
                    dark: '#0A0E1A',
                    card: '#111827',
                    hover: '#1F2937',
                },
            },
            backdropBlur: {
                xs: '2px',
            },
        },
    },
    plugins: [
        forms,
        require('tailwindcss-rtl'),
    ],
};
