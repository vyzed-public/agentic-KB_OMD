# #1: Enable: Workflow Automation to record web-based GitHub issues into archive/issues

**State:** OPEN
**Author:** vyzed
**Created:** 2026-09-02T23:57:41Z

---

### Our process:
1. Use the web GUI to create new file: `.github/workflows/sync-issues.yml`
2. ...that contains the following CI code for **Workflow Automation** CI code

...which is YAML that **archives & updates the web-based UX for creating/editing issues**
into a per-project dir structure: `./archive/issues` that is: 
* easily downloadable (w/ a standard `git pull` ) onto local machines for additional processing
* thus bypassing the "stovepiping" web-based GUI
  * which _seems_ intended to "enhance" platform dependence
    * (because the WebGUI-based GitHub wiki structures can in fact, be `git pull` ops.)

#### Details (for the forgetful):  

> From the GitHub web GUI, the easiest way is:

> Navigate to your repo's `Code` tab;
> Click Add file → Create new file;
> In the filename field, type: `.github/workflows/sync-issues.yml`

> GitHub's web editor will automatically create the nested directories as you type the slashes. Paste in the workflow content, commit, and you're done. GitHub Actions picks it up automatically from that specific path — there's no separate "enable" step.

#### Results:

Behold the marvel and glory of AI-rendered advice in our shiny new: [sync-issues.yml](https://github.com/vyzed-public/agentic-KB_OMD/blob/main/.github/workflows/sync-issues.yml)
