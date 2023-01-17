#pragma once

#include "Points.h"
#include "Centroids.h"


#define DEFAULT_TRESHOLD 0.05f
#define DEFAULT_MAX_IT   3000000


class KMeansAlg
{
public:
	static bool data_check(const Centroids& centroids, const Points& points);

	static void init_centroids(Centroids& centroids, const Points& points);

	static void cpu_version(Points& points, Centroids& centroids, float threshold = DEFAULT_TRESHOLD, int max_it = DEFAULT_MAX_IT);
};

