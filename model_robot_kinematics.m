function qdot = model_robot_kinematics(q,eta)
% MODEL_ROBOT_KINEMATICS  Nonholonomic planar AMR model_robot_kinematics.
theta=q(3); v=eta(1); w=eta(2);
qdot=[v*cos(theta);v*sin(theta);w];
end
