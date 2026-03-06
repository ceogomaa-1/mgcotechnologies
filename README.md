# MG&CO Technologies

This repo now contains:
- A full mirrored source clone of the Framer site in `site/`
- A Vite + React codebase in `mgco-react/` that serves the mirrored pages through React routing

## React App
Path: `mgco-react/`

Commands:
```powershell
cd mgco-react
npm install
npm run dev
```

Build:
```powershell
cd mgco-react
npm run build
```

## Mirror Source
Path: `site/`

Rebuild mirror from Framer:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/mirror-framer.ps1
```

If you rebuild `site/`, copy it to the React app:
```powershell
Remove-Item -Recurse -Force mgco-react/public/mirror/*
Copy-Item -Recurse -Force site/* mgco-react/public/mirror/
```
