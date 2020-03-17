export function statsBetween(statisticAfter, statisticBefore) {
  let newlyInfected = statisticAfter.numInfected - statisticBefore.numInfected;
  let infectedBefore = statisticBefore.numInfected - statisticBefore.numRecovered - statisticBefore.numDead;
  let infectedNow = statisticAfter.numInfected - statisticAfter.numRecovered - statisticAfter.numDead;
  let dailyIncrease = newlyInfected/infectedBefore;
  let timeDistance = (statisticAfter.atTimestamp - statisticBefore.atTimestamp)/(60*60)
  let hourlyIncreate = Math.pow(dailyIncrease+1, 1/timeDistance)-1
  let hoursToDouble = hourlyIncreate == 0 ? 0 : Math.log(2)/Math.log(1+hourlyIncreate)

  return {
    timeDistance: timeDistance,
    date: statisticAfter.at,
    hoursToDouble: hoursToDouble,
    daysToDouble: hoursToDouble/24,
    growth: dailyIncrease,
    now: infectedNow,
  };
}
