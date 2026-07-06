# Publish AirMosaic AI Web

The current web source is a static site:

```text
index.html
styles.css
app.js
```

It can be published without a backend server.

## Option 1: GitHub Pages

Use this when the website should live with the open-source web repository.

Official docs: <https://docs.github.com/pages/quickstart>

1. Push `airmosaic-ai-web` to a GitHub repository.
2. Make sure `index.html` is in the repository root.
3. Open repository `Settings`.
4. Open `Pages`.
5. Choose the `main` branch and root folder as the publishing source.
6. Save and wait for the Pages URL.

GitHub Pages publishes static files pushed to a repository and supports branch or workflow-based publishing.

## Option 2: Vercel

Use this when you want the easiest migration path to a future React or Next.js application.

Official docs: <https://vercel.com/docs/deployments>

1. Push `airmosaic-ai-web` to GitHub.
2. Import the repository in Vercel.
3. Keep build settings empty for this static version.
4. Deploy.

For a quick manual deployment, Vercel Drop can deploy a folder by dragging it into the browser.

## Option 3: Cloudflare Pages

Use this when you want static hosting, preview deployments, and custom-domain management.

Official docs:

- Git integration: <https://developers.cloudflare.com/pages/configuration/git-integration/>
- Direct Upload: <https://developers.cloudflare.com/pages/get-started/direct-upload/>

1. Push `airmosaic-ai-web` to GitHub.
2. In Cloudflare, open Workers & Pages.
3. Create a Pages project.
4. Import the GitHub repository.
5. Use no build command and root output for this static version.
6. Deploy.

## Recommendation

Start with GitHub Pages if you want the simplest public project site. Use Vercel if the site will soon become a Next.js application. Use Cloudflare Pages if custom domain and edge hosting are priorities.
