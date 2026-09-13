# Deployment Policy

- Preview or non-production deployments may be automated if the project supports them.
- Production deployment requires human approval by default.
- Deployment commands should be reproducible.
- Protected credentials must be injected by the execution environment, never stored in the repository.
