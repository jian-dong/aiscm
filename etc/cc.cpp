#include <iostream>
#include <opencv2/aruco/charuco.hpp>
#include <opencv2/imgcodecs.hpp>

using namespace std;

int main(void)
{
  // cv::Mat m(cv::imread("board.png", cv::IMREAD_GRAYSCALE));
  cv::Mat m(cv::imread("board.png"));
  cv::Ptr<cv::aruco::Dictionary> dict = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_100);
  // cv::Ptr<cv::aruco::CharucoBoard> charuco = cv::aruco::CharucoBoard::create(5, 7, 0.04, 0.02, dict);
  std::vector<int> markerIds;
  std::vector<std::vector<cv::Point2f>> markerCorners;
  cv::aruco::detectMarkers(m, dict, markerCorners, markerIds);
  cout << m.cols << "x" << m.rows << ": " << markerIds.size() << endl;
  return 0;
}