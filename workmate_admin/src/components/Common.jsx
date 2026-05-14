import React from 'react';

export const API_URL = "http://localhost:5000/api";

export const Icon = ({ name, fill = 0, className = "" }) => (
  <span className={`material-symbols-outlined ${fill ? 'fill-icon' : ''} ${className}`}>
    {name}
  </span>
);

export const NavItem = ({ icon, label, active, onClick }) => (
  <button 
    onClick={onClick} 
    className={`w-full flex items-center gap-4 px-6 py-4 rounded-2xl transition-all duration-300 group ${
      active 
      ? 'bg-primary text-white shadow-lg shadow-primary/25 font-black scale-[1.02]' 
      : 'text-on-surface-variant hover:bg-surface-container-low hover:text-on-surface'
    }`}
  >
    <Icon 
      name={icon} 
      fill={active ? 1 : 0} 
      className={`!text-[22px] transition-transform duration-500 ${active ? '' : 'group-hover:scale-110 group-hover:rotate-6'}`} 
    />
    <span className="text-xs uppercase tracking-[0.15em] leading-none">{label}</span>
  </button>
);
