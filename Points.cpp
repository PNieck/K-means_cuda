#include "Points.h"

#include <utility>

Points::Points() : Coordinates()
{
	this->centroids_indexes = nullptr;
}


Points::Points(int size, int dim_cnt): Coordinates(size, dim_cnt)
{
	this->centroids_indexes = new int[size];
}


Points::Points(const Points& points): Coordinates(points)
{
	if (this->cnt != points.cnt) {
		delete[] this->centroids_indexes;
		this->centroids_indexes = new int[points.cnt];
	}
	
	for (int i = 0; i < points.cnt; i++) {
		this->centroids_indexes[i] = points.centroids_indexes[i];
	}
}


Points::Points(Points&& points): Coordinates(std::move(points))
{
	this->centroids_indexes = points.centroids_indexes;
	points.centroids_indexes = nullptr;
}


Points& Points::operator=(const Points& points)
{
	if (this != &points) {
		(Coordinates&)*this = points;

		if (this->cnt != points.cnt) {
			delete[] this->centroids_indexes;
			this->centroids_indexes = new int[points.cnt];
		}

		for (int i = 0; i < points.cnt; i++) {
			this->centroids_indexes[i] = points.centroids_indexes[i];
		}
	}

	return *this;
}


Points& Points::operator=(Points&& points) noexcept
{
	if (this != &points)
	{
		(Coordinates&)*this = std::move(points);

		this->centroids_indexes = points.centroids_indexes;
		points.centroids_indexes = nullptr;
	}

	return *this;
}


Points::~Points()
{
	if (centroids_indexes == nullptr)
		return;

	delete[] this->centroids_indexes;
}


void Points::clear_indexes()
{
	for (int i = 0; i < cnt; i++)
		centroids_indexes[i] = -1;
}
