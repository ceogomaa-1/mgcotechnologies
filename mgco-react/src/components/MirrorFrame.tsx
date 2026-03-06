import { useEffect, useMemo, useRef } from "react";
import { useNavigate } from "react-router-dom";

type MirrorFrameProps = {
  routePath: string;
};

function toMirrorSrc(pathname: string): string {
  if (pathname === "/") {
    return "/mirror/";
  }
  return `/mirror${pathname}/`;
}

function normalizeAppPath(url: URL): string {
  const path = url.pathname.endsWith("/") && url.pathname.length > 1
    ? url.pathname.slice(0, -1)
    : url.pathname;
  return path || "/";
}

export function MirrorFrame({ routePath }: MirrorFrameProps) {
  const navigate = useNavigate();
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const mirrorSrc = useMemo(() => toMirrorSrc(routePath), [routePath]);

  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe) return;

    const handleLoad = () => {
      const doc = iframe.contentDocument;
      const win = iframe.contentWindow;
      if (!doc || !win) return;

      const clickHandler = (event: MouseEvent) => {
        const target = event.target as Element | null;
        if (!target) return;
        const anchor = target.closest("a[href]") as HTMLAnchorElement | null;
        if (!anchor) return;
        if (anchor.target && anchor.target !== "_self") return;
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;

        const href = anchor.getAttribute("href");
        if (!href || href.startsWith("mailto:") || href.startsWith("tel:")) return;

        const resolved = new URL(href, win.location.href);
        if (resolved.origin !== window.location.origin) return;
        if (!resolved.pathname.startsWith("/")) return;

        const nextPath = normalizeAppPath(resolved);
        event.preventDefault();
        navigate(`${nextPath}${resolved.search}${resolved.hash}`);
      };

      doc.addEventListener("click", clickHandler);
    };

    iframe.addEventListener("load", handleLoad);
    return () => {
      iframe.removeEventListener("load", handleLoad);
    };
  }, [navigate, mirrorSrc]);

  return (
    <main className="mirror-shell">
      <iframe
        key={mirrorSrc}
        ref={iframeRef}
        className="mirror-frame"
        title="MG&CO Website Mirror"
        src={mirrorSrc}
      />
    </main>
  );
}
