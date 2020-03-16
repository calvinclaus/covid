import React from "react";
import nl2br from "react-nl2br";

export function getAnchorOrName(statistic, periodType) {
  let link = getLink(statistic, periodType);
  if (!link) {
    return statistic.name;
  }
  return <a href={link} target={getLinkTarget(link)}>{nl2br(statistic.name)}</a>
}

export function getLink(s, periodType) {
  if (periodType === "queries") {
    return s.filterQuery;
  }
  if (!s.data || !s.data.id) { return null; }
  let prefix = window.location.href.includes("backend") ? "/backend" : "";
  if (periodType === "campaigns") {
    return prefix+"/campaigns/"+s.data.id;
  }
  if (periodType === "searches") {
    return prefix+"/searches/"+s.data.id;
  }
}
export function getLinks(statistics, periodType) {
  return statistics.map(s => getLink(s, periodType));
}

export function getLinkTarget(link) {
  return link.includes("http") ? "_blank" : "_self";
}

