import Foundation
import CoreLocation
import KabarCore

/// One foreground sample. No background mode or Always permission is requested.
final class LocationSampler: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var resolving = false
    private let completion: (GpsPoint?,String) -> Void
    private var timer: DispatchWorkItem?
    private var finished = false, requested = false
    init(completion: @escaping (GpsPoint?,String) -> Void) { self.completion = completion; super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyHundredMeters }
    func start() {
        guard !finished else { return }
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            guard !requested else { return }; requested = true
            let work = DispatchWorkItem { [weak self] in self?.finish(nil,"Lokasi belum didapat. Status tetap disimpan tanpa lokasi baru.") }
            timer = work; DispatchQueue.main.asyncAfter(deadline:.now()+12,execute:work); manager.requestLocation()
        default: finish(nil,"Izin lokasi belum diberikan. Status tetap disimpan tanpa lokasi baru.")
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { start() }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let point = locations.filter({ $0.horizontalAccuracy>0 && Date().timeIntervalSince($0.timestamp)>=0 && Date().timeIntervalSince($0.timestamp)<=120 }).min(by:{ $0.horizontalAccuracy<$1.horizontalAccuracy }) else { return }
        guard !finished, !resolving else {return};resolving=true;timer?.cancel();manager.stopUpdatingLocation()
        do {
            let fallback=try GpsPoint(lat:point.coordinate.latitude,lon:point.coordinate.longitude,accuracy:point.horizontalAccuracy,at:Int64(point.timestamp.timeIntervalSince1970*1000),zone:TimeZone.current.identifier)
            let timeout=DispatchWorkItem { [weak self] in self?.finish(fallback,"") };timer=timeout;DispatchQueue.main.asyncAfter(deadline:.now()+2.5,execute:timeout)
            geocoder.reverseGeocodeLocation(point) { [weak self] places,_ in
                var named=fallback
                if let p=places?.first {named.city=Self.clean(p.locality ?? p.subAdministrativeArea);named.place=Self.clean(p.subLocality ?? p.administrativeArea)}
                self?.finish(named,"")
            }
        }
        catch { finish(nil,"Lokasi tidak valid. Status tetap disimpan tanpa lokasi baru.") }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code != .locationUnknown { finish(nil,"Lokasi belum tersedia. Status tetap disimpan tanpa lokasi baru.") }
    }
    func cancel() { finish(nil,"Pengambilan lokasi dihentikan. Status tetap disimpan.") }
    private static func clean(_ raw:String?)->String? {guard let raw else {return nil};let text=String(raw.unicodeScalars.filter{$0.value>=32});var value=String(text.prefix(32));while value.utf16.count>32 {value.removeLast()};return value}
    private func finish(_ point: GpsPoint?,_ message: String) { guard !finished else { return }; finished = true; timer?.cancel(); geocoder.cancelGeocode();manager.stopUpdatingLocation(); completion(point,message) }
}
