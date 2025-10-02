import React from "react";

type IconProps = React.SVGProps<SVGSVGElement>;

const ClipboardIcon: React.FC<IconProps> = (props) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    fill="currentColor"
    viewBox="0 0 24 24"
    width="1em"
    height="1em"
    {...props}
  >
    <path d="M16 2h-2.5a2.5 2.5 0 0 0-5 0H6a2 2 0 0 0-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4a2 2 0 0 0-2-2zm-5 0a.5.5 0 0 1 1 0v1h-1V2zm7 18H6V4h2v2h8V4h2v16z" />
  </svg>
);

export default ClipboardIcon;
