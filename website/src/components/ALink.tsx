import { A } from "@solidjs/router";
import { Link, type LinkRootProps } from "@kobalte/core/link";
import type { PolymorphicProps } from "@kobalte/core";

// REFERENCE AS <ALink-component-implementation>
function ALink(props: PolymorphicProps<typeof A, LinkRootProps<typeof A>>) {
  return <Link as={A} {...props} />;
}
export default ALink;
