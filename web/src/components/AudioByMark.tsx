/** Manga speech bubble + sonic bars — even-odd fill. */
const MARK_PATH =
  "M5 4.2h22c2.1 0 3.8 1.7 3.8 3.8v11.2c0 2.1-1.7 3.8-3.8 3.8H14.2L8.2 29.2 9.6 23H5c-2.1 0-3.8-1.7-3.8-3.8V8c0-2.1 1.7-3.8 3.8-3.8zM9.6 10.4h3v8.6h-3v-8.6zM14.5 8.2h3v10.8h-3V8.2zM19.4 9.5h3v9.5h-3V9.5z";

export function AudioByMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} fill="currentColor" aria-hidden="true">
      <path fillRule="evenodd" d={MARK_PATH} />
    </svg>
  );
}
