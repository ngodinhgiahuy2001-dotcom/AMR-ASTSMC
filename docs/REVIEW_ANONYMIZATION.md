# Anonymous-Review Checklist

**Status:** The source repository is managed privately under an identifiable account. Its owner URL and existing commit metadata may disclose identity even if comments and MATLAB filenames are neutral.

If the target journal or conference uses **double-anonymous review**, follow the venue's instructions and check every channel through which reviewers could infer authorship.

## Check before sharing

- [ ] Remove names, affiliations, email addresses, local home paths and acknowledgements from public-facing documentation.
- [ ] Inspect file names, source comments, MATLAB MAT metadata, image annotations and PDF properties.
- [ ] Inspect Git author/committer metadata, historical commits, issue discussions and links to personal profiles.
- [ ] Avoid URLs redirecting to an identifying owner during anonymous review.
- [ ] Confirm what the review venue permits: private reviewer access, an anonymous mirror, or an anonymized ZIP artifact.
- [ ] Verify anonymous links from a signed-out browser and confirm they do not expose the original repository.
- [ ] Keep an internal mapping of the submission artifact and the exact source commit for later publication.

## Delivery choices

**Private GitHub repository:** Suitable for internal collaboration, but private does not mean anonymized to collaborators.

**Neutral owner / organization:** Transfer to an approved neutral account if appropriate, after reviewing Git history and organizational membership. Merely renaming the repository does not hide the original owner segment of its URL.

**Anonymous mirror:** A read-only anonymization service may be appropriate if venue policy allows it. Grant any third-party service access to private source only after considering its privacy and disclosure implications. Do not assume that redacting text automatically sanitizes images, PDFs or external references.

## Final publication

After review, publish under the authorized authorship, finalize `CITATION.cff` and licensing, attach a stable release or DOI when available, and update the paper's Code Availability statement to a working, accessible URL.
