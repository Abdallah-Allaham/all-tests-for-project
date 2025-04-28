package com.example.sos_plugin;

import android.content.Context;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;

import io.flutter.plugin.common.EventChannel;

public class LocationChecker implements EventChannel.StreamHandler {
    private double homeLatitude;
    private double homeLongitude;
    private boolean isHomeLocationSet = false;
    private final Context context;
    private LocationManager locationManager;
    private EventChannel.EventSink events;
    private LocationListener locationListener;

    public LocationChecker(Context context) {
        this.context = context;
        this.locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
    }

    public void setHomeLocation(double latitude, double longitude) {
        this.homeLatitude = latitude;
        this.homeLongitude = longitude;
        this.isHomeLocationSet = true;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.events = events;

        locationListener = new LocationListener() {
            @Override
            public void onLocationChanged(Location location) {
                if (!isHomeLocationSet) {
                    events.success(false);
                    return;
                }

                float[] distance = new float[1];
                Location.distanceBetween(
                        location.getLatitude(), location.getLongitude(),
                        homeLatitude, homeLongitude, distance);

                boolean isOutsideHome = distance[0] > 5; // أكثر من 50 متر
                events.success(isOutsideHome);
            }

            @Override
            public void onStatusChanged(String provider, int status, android.os.Bundle extras) {}
            @Override
            public void onProviderEnabled(String provider) {}
            @Override
            public void onProviderDisabled(String provider) {}
        };

        try {
            locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER, 1000, 1, locationListener);
        } catch (SecurityException e) {
            events.error("LOCATION_ERROR", "Location permission denied", null);
        }
    }

    @Override
    public void onCancel(Object arguments) {
        if (locationListener != null) {
            locationManager.removeUpdates(locationListener);
            locationListener = null;
        }
        events = null;
    }
}