"use client";

import { motion, useInView } from "framer-motion";
import type { LucideIcon } from "lucide-react";
import { useRef } from "react";

type FeatureCardProps = {
  title: string;
  description: string;
  Icon: LucideIcon;
  index: number;
};

export default function FeatureCard({ title, description, Icon, index }: FeatureCardProps) {
  const ref = useRef<HTMLDivElement | null>(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 50 }}
      animate={isInView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.5, delay: index * 0.1 }}
      className="rounded-2xl border border-gray-800 bg-gray-900/40 p-6 backdrop-blur-sm"
    >
      <div className="mb-6 flex h-12 w-12 items-center justify-center rounded-xl bg-gray-800">
        <Icon size={24} className="text-white" />
      </div>
      <h3 className="mb-3 text-xl font-semibold">{title}</h3>
      <p className="text-sm leading-relaxed text-gray-400 md:text-base">{description}</p>
    </motion.div>
  );
}