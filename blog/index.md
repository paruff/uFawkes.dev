---
layout: page
title: Build in public blog
description: "Notes from building the uFawkes platform engineering stacks in the open: decisions, results and what went wrong."
permalink: /blog/
---

{% if site.posts.size > 0 %}
{% for post in site.posts limit:10 %}

## [{{ post.title }}]({{ post.url | relative_url }})

_{{ post.date | date: "%B %-d, %Y" }}_

{{ post.excerpt | default: post.content | strip_html | truncate: 220 }}

{% endfor %}
{% else %}
No posts yet. Check back soon.
{% endif %}
