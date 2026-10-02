import Foundation
import CoreLocation
import KabarCore

/// One foreground sample. No background mode or Always permission is requested.
final class LocationSampler: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
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
        do { finish(try GpsPoint(lat:point.coordinate.latitude,lon:point.coordinate.longitude,accuracy:point.horizontalAccuracy,at:Int64(point.timestamp.timeIntervalSince1970*1000),zone:TimeZone.current.identifier),"") }
        catch { finish(nil,"Lokasi tidak valid. Status tetap disimpan tanpa lokasi baru.") }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code != .locationUnknown { finish(nil,"Lokasi belum tersedia. Status tetap disimpan tanpa lokasi baru.") }
    }
    func cancel() { finish(nil,"Pengambilan lokasi dihentikan. Status tetap disimpan.") }
    private func finish(_ point: GpsPoint?,_ message: String) { guard !finished else { return }; finished = true; timer?.cancel(); manager.stopUpdatingLocation(); completion(point,message) }
}
