//
//  Praytimes.swift
//
//
//  Created by M. Akif Petek on 18/11/14.
//  Copyright (c) 2014 M. Akif Petek. All rights reserved.
//

import Foundation

class PrayTimes {

    // Calculation Methods
    var Jafari: Int = 0
    // Ithna Ashari
    var Karachi: Int = 1
    // University of Islamic Sciences, Karachi
    var ISNA: Int = 2
    // Islamic Society of North America (ISNA)
    var MWL: Int = 3
    // Muslim World League (MWL)
    var Makkah: Int = 4
    // Umm al-Qura, Makkah
    var Egypt: Int = 5
    // Egyptian General Authority of Survey
    var Tehran: Int = 6
    // Institute of Geophysics, University of Tehran
    var Custom: Int = 7
    // Custom Setting


    // Juristic Methods
    var Shafii: Int = 0
    // Shafii (standard)
    var Hanafi: Int = 1
    // Hanafi

    // Adjusting Methods for Higher Latitudes
    var None: Int = 0
    // No adjustment
    var MidNight: Int = 1
    // middle of night
    var OneSeventh: Int = 2
    // 1/7th of night
    var AngleBased: Int = 3
    // angle/60th of night


    // Time Formats
    var Time24: Int = 0
    // 24-hour format
    var Time12: Int = 1
    // 12-hour format
    var Time12NS: Int = 2
    // 12-hour format with no suffix
    var Float: Int = 3
    // floating point number


    // Time Names
    var timeNames: Array<String>

    var InvalidTime: String = "-----"
    // The string used for invalid times


    //--------------------- Technical Settings --------------------

    var numIterations: Int = 1
    // number of iterations needed to compute times

    //------------------- Calc Method Parameters --------------------


    var methodParams: Dictionary<Int, NSMutableArray>
//    var methodParams: NSMutableDictionary

    /*  this.methodParams[methodNum] = new Array(fa, ms, mv, is, iv);
    
    fa : fajr angle
    ms : maghrib selector (0 = angle; 1 = minutes after sunset)
    mv : maghrib parameter value (in angle or minutes)
    is : isha selector (0 = angle; 1 = minutes after maghrib)
    iv : isha parameter value (in angle or minutes)
    */
    var prayerTimesCurrent: NSMutableArray
    var offsets: Array = Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])


    ////---------------------- Global Variables --------------------


    var calcMethod: Int = 0; // caculation method
    var asrJuristic: Int = 1; // Juristic method for Asr
    var dhuhrMinutes: Int = 0; // minutes after mid-day for Dhuhr
    var adjustHighLats: Int = 1; // adjusting method for higher latitudes

    var timeFormat: Int = 0
    // time format

    var lat: Double = 0
    // latitude
    var lng: Double = 0
    // longitude
    var timeZone: Double = 0
    // time-zone
    var JDate: Double = 0
    // Julian date


    init() {

        self.prayerTimesCurrent = NSMutableArray()
        //self.offsets = [0, 0, 0, 0, 0, 0, 0]

//        self.methodParams = NSMutableDictionary(capacity: 8)
        self.methodParams = Dictionary(minimumCapacity: 8)

        self.methodParams[Jafari] = [16, 0, 4, 0, 14]
        self.methodParams[Karachi] = [18, 1, 0, 0, 18]
        self.methodParams[ISNA] = [15, 1, 0, 0, 15]
        self.methodParams[MWL] = [18, 1, 0, 0, 17]
        self.methodParams[Makkah] = [18.5, 1, 0, 1, 90]
        self.methodParams[Egypt] = [19.5, 1, 0, 0, 17.5]
        self.methodParams[Tehran] = [17.7, 0, 4.5, 0, 14]
        self.methodParams[Custom] = [18, 1, 0, 0, 17]

        self.timeNames = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha"]

        calcMethod = MWL
        asrJuristic = Hanafi

        /*
        fa : fajr angle
        ms : maghrib selector (0 = angle; 1 = minutes after sunset)
        mv : maghrib parameter value (in angle or minutes)
        is : isha selector (0 = angle; 1 = minutes after maghrib)
        iv : isha parameter value (in angle or minutes)
        */
    }

    ////---------------------- Trigonometric Functions -----------------------

    // range reduce angle in degrees.
    func fixangle(_ a: Double) -> Double {
        var a = a

        a = a - (360 * (floor(a / 360.0)));

        a = a < 0 ? (a + 360) : a;

        return a;
    }

    // range reduce hours to 0..23
    func fixhour(_ a: Double) -> Double {
        var a = a
        a = a - 24.0 * floor(a / 24.0);
        a = a < 0 ? (a + 24) : a;
        return a;
    }

    // radian to degree
    func radiansToDegrees(_ alpha: Double) -> Double {
        return ((alpha * 180.0) / .pi);
    }

    //deree to radian
    func DegreesToRadians(_ alpha: Double) -> Double {
        return ((alpha * .pi) / 180.0);
    }

    // degree sin
    func dsin(_ d: Double) -> Double {
        return (sin(DegreesToRadians(d)));
    }

    // degree cos
    func dcos(_ d: Double) -> Double {
        return (cos(DegreesToRadians(d)));
    }

    // degree tan
    func dtan(_ d: Double) -> Double {
        return (tan(DegreesToRadians(d)));
    }

    // degree arcsin
    func darcsin(_ x: Double) -> Double {
        let val = asin(x);
        return radiansToDegrees(val)
    }

    // degree arccos
    func darccos(_ x: Double) -> Double {
        let val = acos(x);
        return radiansToDegrees(val)
    }

    // degree arctan
    func darctan(_ x: Double) -> Double {
        let val = atan(x);
        return radiansToDegrees(val)
    }

    // degree arctan2
    func darctan2(_ y: Double, x: Double) -> Double {
        let val = atan2(y, x);
        return radiansToDegrees(val)
    }

    // degree arccot
    func darccot(_ x: Double) -> Double {
        let val = atan2(1.0, x);
        return radiansToDegrees(val)
    }

    //---------------------- Time-Zone Functions -----------------------

    // compute local time-zone for a specific date
    func getTimeZone() -> Double {

        let timeZone = TimeZone.autoupdatingCurrent
        let hoursDiff = Double(timeZone.secondsFromGMT() / 3600)

        return hoursDiff;
    }

    // compute base time-zone of the system
    func getBaseTimeZone() -> Double {

        let timeZone = TimeZone.current
        let hoursDiff = Double(timeZone.secondsFromGMT() / 3600)
        return hoursDiff;

    }

    // detect daylight saving in a given date
    func detectDaylightSaving() -> Double {

        let timeZone = TimeZone.autoupdatingCurrent
        let hoursDiff = Double(timeZone.daylightSavingTimeOffset(for: Date()))

        return hoursDiff;
    }

    //---------------------- Julian Date Functions -----------------------
    // calculate julian date from a calendar date
    func julianDate(_ year: Int, month: Int, day: Int) -> Double {
        var year = year, month = month

        if (month <= 2) {
            year = year - 1
            month = month + 12
        }

        let A = Double(floor(Double(year) / 100.0))

        let B = 2 - A + floor(A / 4.0)

        let yearDays: Double = 365.25
        let tempYear: Double = Double(year) + 4716

        let jd1: Double = floor((yearDays * tempYear))
        let jd2: Double = floor(30.6001 * Double(Double(month) + Double(1)))
        let jd3: Double = Double(day) + B - 1524.5
        let JD: Double =  jd1 + jd2 + jd3

        return JD;
    }

    // convert a calendar date to julian date (second method)
    func calcJD(_ year: Int, month: Int, day: Int) -> Double {

        let J1970: Double = 2440588;

        var components = DateComponents()
        components.weekday = day // Monday
        // components.weekdayOrdinal = 1 // The first day in the month

        components.month = month //May
        components.year = year

        let gregorianCalendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let date1 = gregorianCalendar.date(from: components)

        let ms = date1?.timeIntervalSince1970 // # of milliseconds since midnight Jan 1, 1970
        let days = floor(ms! / (1000 * 60 * 60 * 24))

        return J1970 + days - 0.5;
    }

    //---------------------- Calculation Functions -----------------------
    //// References:
    //// http://www.ummah.net/astronomy/saltime
    //// http://aa.usno.navy.mil/faq/docs/SunApprox.html

    // compute declination angle of sun and equation of time
    func sunPosition(_ jd: Double) -> NSMutableArray {

        let D: Double = jd - 2451545
        let g: Double = fixangle((Double(357.529) + Double(0.98560028) * D))
        let q: Double = fixangle((Double(280.459) + Double(0.98564736) * D))
        let L: Double = fixangle((q + (1.915 * dsin(g)) + (0.020 * dsin(2 * g))))

        //let R = 1.00014 - 0.01671 * dcos(g) - 0.00014 * dcos(2 * g)
        let e: Double = 23.439 - (0.00000036 * D)

        let RA: Double = darctan2(dcos(e) * dsin(L), x: dcos(L)) / 15
        let EqT = q / 15.0 - fixhour(RA)
        let d: Double = darcsin(dsin(e) * dsin(L))

        let sPosition = NSMutableArray(array: [d, EqT])

        return sPosition;
    }

    // compute equation of time
    func equationOfTime(_ jd: Double) -> Double {

        return (sunPosition(jd).object(at: 1) as AnyObject).doubleValue
    }

    // compute declination angle of sun
    func sunDeclination(_ jd: Double) -> Double {

        return (sunPosition(jd).object(at: 0) as AnyObject).doubleValue
    }

    //// compute mid-day (Dhuhr, Zawal) time
    func computeMidDay(_ t: Double) -> Double {

        let T: Double = equationOfTime(JDate + t)
        let Z: Double = fixhour(12 - T)

        return Z;
    }

    // compute time for a given angle G
    func computeTime(_ G: Double, t: Double) -> Double {

        let D: Double = sunDeclination(JDate + t)
        let Z: Double = computeMidDay(t)
        let V: Double = 1 / 15 * darccos((-dsin(G) - dsin(D) * dsin(lat)) / (dcos(D) * dcos(lat)))

        print(lat)
        return Z + (G > 90 ? -V : V);
    }

    // compute the time of Asr
    // Shafii: step=1, Hanafi: step=2
    func computeAsr(_ step: Double, time: Double) -> Double {

        let D: Double = sunDeclination(JDate + time)
        let G: Double = -darccot((step + dtan(abs(lat - D))))

        return computeTime(G, t: time)
    }

    //---------------------- Misc Functions -----------------------

    // compute the difference between two times
    func timeDiff(_ time1: Double, time2: Double) -> Double {

        return fixhour(time2 - time1)
    }

    //-------------------- Interface Functions --------------------

    //// return prayer times for a given date
    func getDatePrayerTimes(_ year: Int, month: Int, day: Int, latitude: Double, longitude: Double, timeZone: Double) -> NSMutableArray {

        //timeZone = this.effectiveTimeZone(year, month, day, timeZone);
        //timeZone = [self getTimeZone];
        JDate = julianDate(year, month: month, day: day)

        let lonDiff: Double = longitude / (15.0 * 24.0);
        JDate = JDate - lonDiff;

        return computeDayTimes()
    }

    // return prayer times for a given date
    func getPrayerTimes(_ date: DateComponents, latitude: Double, longitude: Double, timeZone: Double) -> NSMutableArray {

        let year: Int = date.year!
        let month: Int = date.month!
        let day: Int = date.day!

        self.lat = latitude
        self.lng = longitude
        self.timeZone = timeZone

        //elv = coords[2] ? 1* coords[2] : 0;
        //timeFormat = format || timeFormat;
//        if (date.constructor === Date)
//        date = [date.getFullYear(), date.getMonth()+ 1, date.getDate()];
//        if (typeof(timezone) == 'undefined' || timezone == 'auto')
//        timezone = this.getTimeZone(date);
//        if (typeof(dst) == 'undefined' || dst == 'auto')
//        dst = this.getDst(date);
//        timeZone = 1* timezone+ (1* dst ? 1 : 0);
//        jDate = this.julian(date[0], date[1], date[2])- lng/ (15* 24);

        print("\(year) / \(month) / \(day) ------ lat: \(self.lat) x long: \(self.lng)    tz: \(self.timeZone)")

        return getDatePrayerTimes(year, month: month, day: day, latitude: self.lat, longitude: self.lng, timeZone: 2)
//        return getDatePrayerTimes(2014, month: 11, day: 29, latitude: 28.9647222, longitude: 41.0186111, timeZone: 3)
    }

    // set the calculation method
    func setCalcMethod(_ methodID: Int) {

        calcMethod = methodID
    }

    // set the juristic method for Asr
    func setAsrMethod(_ methodID: Int) {

        if (methodID < 0 || methodID > 1) {
            return
        }

        asrJuristic = methodID;
    }

    // set custom values for calculation parameters
    func setCustomParams(_ params: NSMutableArray) -> Void {

        var j: AnyObject
        let Cust: AnyObject! = self.methodParams[Custom]
        let cal: NSMutableArray = self.methodParams[calcMethod]!

        for i in 0 ..< 5 {
            j = params.object(at: i) as AnyObject

            if (j.isEqual(to: NSNumber(value: -1 as Int32))) {

                Cust?.replaceObject(at: i, with: cal.object(at: i))

            } else {

                Cust?.replaceObject(at: i, with: params.object(at: i))
            }
        }

        calcMethod = Custom;
    }

    // set the angle for calculating Fajr
    func setFajrAngle(_ angle: Double) -> Void {

        let params = NSMutableArray(array: [angle, -1, -1, -1, -1])

//        params.addObject(NSNumber(double: angle))
//        params.addObject(NSNumber(double: -1))
//        params.addObject(NSNumber(double: -1))
//        params.addObject(NSNumber(double: -1))
//        params.addObject(NSNumber(double: -1))

        self.setCustomParams(params)
    }

    // set the angle for calculating Maghrib
    func setMaghribAngle(_ angle: Double) {

        let params = NSMutableArray(array: [-1, 0, angle, -1, -1])

        self.setCustomParams(params)
    }

    // set the angle for calculating Isha
    func setIshaAngle(_ angle: Double) {

        let params = NSMutableArray(array: [-1, -1, -1, 0, angle])

        self.setCustomParams(params)
    }

    // set the minutes after mid-day for calculating Dhuhr
    func setDhuhrMinutes(_ minutes: Int) {

        dhuhrMinutes = minutes
    }

    // set the minutes after Sunset for calculating Maghrib
    func setMaghribMinutes(_ minutes: Double) {

        let params = NSMutableArray(array: [-1, 1, minutes, -1, -1])

        self.setCustomParams(params)
    }

    // set the minutes after Sunset for calculating Maghrib
    func setIshaMinutes(_ minutes: Double) {

        let params = NSMutableArray(array: [-1, -1, -1, 1, minutes])

        self.setCustomParams(params)
    }

    // set adjusting method for higher latitudes
    func setHighLatsMethod(_ methodID: Int) {

        adjustHighLats = methodID
    }

    // set the time format
    func setTimeFormat(_ tFormat: Int) {

        timeFormat = tFormat
    }

    // convert double hours to 24h format
    func floatToTime24(_ time: Double) -> String {
        var time = time

        var result: String = ""

        if (time.isNaN) {
            return InvalidTime
        }

        time = fixhour(time + 0.5 / 60) // add 0.5 minutes to round
        let hours = Int(floor(time))
        let minutes = Int(floor((time - Double(hours)) * 60.0))

        if ((hours >= 0 && hours <= 9) && (minutes >= 0 && minutes <= 9)) {

            //result = NSString(format: "0%d:0%.0f", hours, minutes)
            result = "0\(hours):0\(minutes)"
        } else if ((hours >= 0 && hours <= 9)) {

            result = "0\(hours):\(minutes)"
        } else if ((minutes >= 0 && minutes <= 9)) {

            result = "\(hours):0\(minutes)"
        } else {

            result = "\(hours):\(minutes)"
        }

        return result;
    }

    // convert double hours to 12h format
    func floatToTime12(_ time: Double, noSuffix: Bool) -> String {
        var time = time

        var result: String = ""

        if (time.isNaN) {
            return InvalidTime
        }

        time = fixhour(time + 0.5 / 60) // add 0.5 minutes to round
        var hours = floor(time)
        let minutes = floor((time - hours) * 60.0)

        var suffix: String

        if (hours >= 12) {
            suffix = "pm";
        } else {
            suffix = "am";
        }

        //hours = ((((hours+ 12) -1) % (12))+ 1);
        hours = (hours + 12) - 1
        var hrs = Int(hours) % 12
        hrs += 1;

        if (noSuffix == false) {

            if ((hrs >= 0 && hrs <= 9) && (minutes >= 0 && minutes <= 9)) {

                result = NSString(format: "0%d:0%.0f", hours, minutes, suffix) as String
            } else if ((hrs >= 0 && hrs <= 9)) {

                result = NSString(format: "0%d:%.0f", hours, minutes, suffix) as String
            } else if ((minutes >= 0 && minutes <= 9)) {

                result = NSString(format: "%d:0%.0f", hours, minutes, suffix) as String
            } else {
                result = NSString(format: "%d:%.0f", hours, minutes, suffix) as String
            }

        } else {
            if ((hrs >= 0 && hrs <= 9) && (minutes >= 0 && minutes <= 9)) {

                result = NSString(format: "0%d:0%.0f", hours, minutes) as String
            } else if ((hrs >= 0 && hrs <= 9)) {

                result = NSString(format: "%d:%.0f", hours, minutes) as String
            } else if ((minutes >= 0 && minutes <= 9)) {

                result = NSString(format: "%d:0%.0f", hours, minutes) as String
            } else {

                result = NSString(format: "%d:%.0f", hours, minutes) as String
            }
        }

        return result
    }

    // convert double hours to 12h format with no suffix
    func floatToTime12NS(_ time: Double) -> String {

        return floatToTime12(time, noSuffix: true)
    }

    //---------------------- Compute Prayer Times -----------------------

    // compute prayer times at given julian date
    func computeTimes(_ times: NSMutableArray) -> NSMutableArray {

        let t = dayPortion(times)

        let settings: NSMutableArray = methodParams[calcMethod]!

        let idk = (settings.object(at: 0) as AnyObject).doubleValue

        let Fajr = computeTime(180 - idk!, t: (t.object(at: 0) as AnyObject).doubleValue)
        let Sunrise = computeTime(180 - 0.833, t: (t.object(at: 1) as AnyObject).doubleValue)
        let Dhuhr = computeMidDay((t.object(at: 2) as AnyObject).doubleValue)
        let Asr = computeAsr(Double(asrJuristic), time: (t.object(at: 3) as AnyObject).doubleValue)
        let Sunset = computeTime(0.833, t: (t.object(at: 4) as AnyObject).doubleValue)
        let Maghrib = computeTime((settings.object(at: 2) as AnyObject).doubleValue, t: (t.object(at: 5) as AnyObject).doubleValue)
        let Isha = computeTime((settings.object(at: 4) as AnyObject).doubleValue, t: (t.object(at: 6) as AnyObject).doubleValue)

        print("\(1 + Double(asrJuristic)) ---- \((t.object(at: 3) as AnyObject).doubleValue)")

        var Ctimes = NSMutableArray(array: [Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha])
        //Tune times here
        Ctimes = tuneTimes(Ctimes)

        return Ctimes;
    }

    // compute prayer times at given julian date
    func computeDayTimes() -> NSMutableArray {

        var t1: NSMutableArray!, t2: NSMutableArray, t3: NSMutableArray

        let times = NSMutableArray(array: [5, 6, 12, 13, 18, 18, 18]) //default times

        for _ in 1 ..< numIterations + 1 {
            t1 = computeTimes(times)
        }

        t2 = adjustTimes(t1)
        t2 = tuneTimes(t2)

        //Set prayerTimesCurrent here!!
        prayerTimesCurrent = NSMutableArray(array: t2)

        t3 = adjustTimesFormat(t2)

        return t3;
    }

    // adjust times in a prayer time array
    func adjustTimes(_ times: NSMutableArray) -> NSMutableArray {
        var times = times

        let mutableArr: NSMutableArray = methodParams[calcMethod]!

        var time: Double = 0
        var Dtime: Double, Dtime1: Double, Dtime2: Double

        for i in 0 ..< 7 {

            time = (times.object(at: i) as AnyObject).doubleValue + timeZone - lng / 15
            times.replaceObject(at: i, with: time)
        }

        Dtime = (times.object(at: 2) as AnyObject).doubleValue + (Double(dhuhrMinutes) / 60) // Dhuhr
        times.replaceObject(at: 2, with: Dtime)

        let val = (mutableArr.object(at: 1) as AnyObject).doubleValue

        if (val == 1) {
            // Maghrib

            Dtime1 = (times.object(at: 4) as AnyObject).doubleValue + ((mutableArr.object(at: 2) as AnyObject).doubleValue / 60)
            times.replaceObject(at: 5, with: Dtime1)
        }

        if ((mutableArr.object(at: 3) as AnyObject).doubleValue == 1) {
            //Isha

            Dtime2 = (times.object(at: 5) as AnyObject).doubleValue + ((mutableArr.object(at: 4) as AnyObject).doubleValue / 60)
            times.replaceObject(at: 6, with: Dtime2)
        }

        if (adjustHighLats != None) {

            times = adjustHighLatTimes(times)
        }

        return times;
    }

    // convert times array to given time format
    func adjustTimesFormat(_ times: NSMutableArray) -> NSMutableArray {

        if (timeFormat == Float) {
            return times
        }

        for i in 0 ..< 7 {

            if (timeFormat == Time12) {

                times.replaceObject(at: i, with: floatToTime12((times.object(at: i) as AnyObject).doubleValue, noSuffix: false))
            } else if (timeFormat == Time12NS) {

                times.replaceObject(at: i, with: floatToTime12((times.object(at: i) as AnyObject).doubleValue, noSuffix: true))
            } else {

                times.replaceObject(at: i, with: floatToTime24((times.object(at: i) as AnyObject).doubleValue))
            }
        }
        return times;
    }



    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    func adjustHighLatTimes(_ times: NSMutableArray) -> NSMutableArray {

        let time0: Double = (times.object(at: 0) as AnyObject).doubleValue
        let time1: Double = (times.object(at: 1) as AnyObject).doubleValue
//        let time2:Double = times.objectAtIndex(2).doubleValue
//        let time3:Double = times.objectAtIndex(3).doubleValue
        let time4: Double = (times.object(at: 4) as AnyObject).doubleValue
        let time5: Double = (times.object(at: 5) as AnyObject).doubleValue
        let time6: Double = (times.object(at: 6) as AnyObject).doubleValue

        let nightTime: Double = timeDiff(time4, time2: time1) // sunset to sunrise

        // Adjust Fajr

        let obj0 = (self.methodParams[calcMethod]!.object(at: 0) as AnyObject).doubleValue
        let obj1 = (self.methodParams[calcMethod]!.object(at: 1) as AnyObject).doubleValue
        let obj2 = (self.methodParams[calcMethod]!.object(at: 2) as AnyObject).doubleValue
        let obj3 = (self.methodParams[calcMethod]!.object(at: 3) as AnyObject).doubleValue
        let obj4 = (self.methodParams[calcMethod]!.object(at: 4) as AnyObject).doubleValue

        let FajrDiff: Double = nightPortion(obj0!) * nightTime

        if (time0.isNaN || (timeDiff(time0, time2: time1) > FajrDiff)) {

            times.replaceObject(at: 0, with: NSNumber(value: (time1 - FajrDiff) as Double))
        }

        // Adjust Isha
        let IshaAngle: Double = (obj3 == 0) ? obj4! : 18;
        let IshaDiff: Double = nightPortion(IshaAngle) * nightTime

        if (time6.isNaN || timeDiff(time4, time2: time6) > IshaDiff) {

            times.replaceObject(at: 6, with: NSNumber(value: (time4 + IshaDiff) as Double))
        }


        // Adjust Maghrib
        let MaghribAngle: Double = (obj1 == 0) ? obj2! : 4;
        let MaghribDiff: Double = nightPortion(MaghribAngle) * nightTime

        if (time5.isNaN || timeDiff(time4, time2: time5) > MaghribDiff) {

            times.replaceObject(at: 5, with: NSNumber(value: (time4 + MaghribDiff) as Double))
        }

        return times;
    }

    // the night portion used for adjusting times in higher latitudes
    func nightPortion(_ angle: Double) -> Double {

        var calc: Double = 0;

        if (adjustHighLats == AngleBased) {

            calc = (angle) / 60.0

        } else if (adjustHighLats == MidNight) {

            calc = 0.5

        } else if (adjustHighLats == OneSeventh) {

            calc = 0.14286
        }

        return calc;
    }

    //convert hours to day portions
    func dayPortion(_ times: NSMutableArray) -> NSMutableArray {

        var time: Double = 0

        for i in 0 ..< 7 {

            time = (times.object(at: i) as AnyObject).doubleValue
            time = time / 24.0;

            times.replaceObject(at: i, with: time)
        }

        return times;
    }

    //Tune timings for adjustments
    //Set time offsets
    /*func tune(_ offsetTimes: Array) -> Void {

        self.offsets[0] = offsetTimes.object(forKey: "fajr")
//        self.offsets.replaceObject(at: 0, with: offsetTimes.object(forKey: "fajr")!)
//        self.offsets.replaceObject(at: 1, with: offsetTimes.object(forKey: "sunrise")!)
//        self.offsets.replaceObject(at: 2, with: offsetTimes.object(forKey: "dhuhr")!)
//        self.offsets.replaceObject(at: 3, with: offsetTimes.object(forKey: "asr")!)
//        self.offsets.replaceObject(at: 4, with: offsetTimes.object(forKey: "sunset")!)
//        self.offsets.replaceObject(at: 5, with: offsetTimes.object(forKey: "maghrib")!)
//        self.offsets.replaceObject(at: 6, with: offsetTimes.object(forKey: "isha")!)
    }
    */

    func tuneTimes(_ times: NSMutableArray) -> NSMutableArray {

        var off: Double, time: Double

        for i in 0 ..< times.count {
            
            off = self.offsets[i] / 60.0
            time = times.object(at: i) as! Double + off
            times.replaceObject(at: i, with: time)

        }

        return times;
    }
}
