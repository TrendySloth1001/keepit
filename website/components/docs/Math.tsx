import katex from "katex";

type Props = { tex: string; display?: boolean };

export default function Math({ tex, display = false }: Props) {
  const html = katex.renderToString(tex, {
    throwOnError: false,
    displayMode: display,
    output: "html",
    strict: "ignore",
  });
  return display ? (
    <div className="math math--display" dangerouslySetInnerHTML={{ __html: html }} />
  ) : (
    <span className="math math--inline" dangerouslySetInnerHTML={{ __html: html }} />
  );
}
