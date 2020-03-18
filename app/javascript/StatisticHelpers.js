export function statsBetween(statisticAfter, statisticBefore) {
  let newlyInfected = statisticAfter.numInfected - statisticBefore.numInfected;
  let infectedBefore = statisticBefore.numInfected - statisticBefore.numRecovered - statisticBefore.numDead;
  let infectedNow = statisticAfter.numInfected - statisticAfter.numRecovered - statisticAfter.numDead;
  let growth = newlyInfected/infectedBefore;
  let timeDistance = (statisticAfter.atTimestamp - statisticBefore.atTimestamp)/(60*60)
  let hourlyIncrease = Math.pow(growth+1, 1/timeDistance)-1
  let hoursToDouble = hourlyIncrease == 0 ? 0 : Math.log(2)/Math.log(1+hourlyIncrease)
  let extrapolated24hChange = Math.pow(hourlyIncrease+1, 24);

  return {
    timeDistance: timeDistance,
    date: statisticAfter.at,
    hourlyIncrease,
    hoursToDouble: hoursToDouble,
    daysToDouble: hoursToDouble/24,
    extrapolated24hChange: extrapolated24hChange-1,
    growth: growth,
    now: infectedNow,
  };
}
