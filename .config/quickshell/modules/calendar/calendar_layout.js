// Month grid math. Monday-first 6x7 grid of {day, today}; today is 1 for
// the current day, -1 for filler days from other months, 0 otherwise.
function leapYear(year) {
    return year % 400 === 0 || (year % 4 === 0 && year % 100 !== 0);
}

function monthDays(month, year) {
    if (month === 2)
        return leapYear(year) ? 29 : 28;
    return [4, 6, 9, 11].includes(month) ? 30 : 31;
}

function shiftedDate(shift) {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth() + shift, 1);
}

function layout(viewing, highlight) {
    const today = new Date();
    const y = viewing.getFullYear();
    const m = viewing.getMonth();
    const lead = (new Date(y, m, 1).getDay() + 6) % 7;
    const dim = monthDays(m + 1, y);
    const prev = new Date(y, m - 1, 1);
    const prevDim = monthDays(prev.getMonth() + 1, prev.getFullYear());
    const next = new Date(y, m + 1, 1);
    const nextDim = monthDays(next.getMonth() + 1, next.getFullYear());

    const grid = [];
    let day = lead === 0 ? 1 : prevDim - lead + 1;
    let diff = lead === 0 ? 0 : -1;
    for (let i = 0; i < 42; i++) {
        const inMonth = diff === 0;
        const isToday = highlight && inMonth && day === today.getDate()
            && m === today.getMonth() && y === today.getFullYear();
        grid.push({ day: day, today: isToday ? 1 : (inMonth ? 0 : -1) });
        day++;
        const lim = diff < 0 ? prevDim : (diff === 0 ? dim : nextDim);
        if (day > lim) {
            day = 1;
            diff++;
        }
    }
    return grid;
}

const weekDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
